clear all
close all

% Adds OET
% run('C:\Users\middl\OneDrive\Documents\Desktop\OET\oetsettings')
mod_dir = 'C:\Users\middl\OneDrive\Documents\Desktop\Matlab Designer Toolbox\Models\clean\';
destout = 'C:\Users\middl\OneDrive\Documents\Desktop\Matlab Designer Toolbox\Models\myrun\';
data = 'C:\Users\middl\OneDrive\Documents\Desktop\Matlab Designer Toolbox\';
cd(data)


%% Data Import
% Sets model directory and output
bathy = readmatrix([mod_dir 'cela1.csv']);
x1 = bathy(:, 3);
y1 = bathy(:, 4);
z1 = bathy(:, 2);

% Making sure the grid aligns to the original data
xq = unique(x1);
yq = unique(y1);
[Xq, Yq] = meshgrid(xq, yq);

% Interpolate Z values onto grid
Zq = griddata(x1, y1, z1, Xq, Yq, 'cubic');

%% **Cleaning the elevation data**
% This can be used to remove outliers in data. Define min and max, then
% remove percent signs on lines 26, 27, and 29

 min = -12
 max = 0

 mask = (Zq < min | Zq > max); % Find cells outside the valid range

%% **Calculating new values for outliers or NaN cells**
% Preallocate local means matrix
local_means = NaN(size(Zq));

% Compute local mean for all cells without padding
%for i = 1:size(Zq, 1)
%    for j = 1:size(Zq, 2)
%        % Define neighborhood bounds
%        i_min = max(i-1, 1); % Ensure bounds don't go below 1
%        i_max = min(i+1, size(Zq, 1)); % Ensure bounds don't exceed size
%        j_min = max(j-1, 1);
%        j_max = min(j+1, size(Zq, 2));
       
        % Extract neighbors
%        neighbors = Zq(i_min:i_max, j_min:j_max);
%        neighbors = neighbors(:);
%        neighbors = neighbors(neighbors >= 3 & neighbors <= 13); % Filter valid neighbors
        
        % Compute mean of neighbors
%        if ~isempty(neighbors)
%            local_means(i, j) = mean(neighbors);
%        else
%            local_means(i, j) = mean(Zq(:), 'omitnan'); % Fallback to global mean
%        end
%    end
%end

% Replace outliers with local means
 Zq(mask) = local_means(mask);

% Verify no NaNs remain
if any(isnan(Zq(:)))
    Zq = fillmissing(Zq, 'nearest', 'EndValues', 'nearest');
end


%% Parameter Setup

% Loads the bathymetry file you created with the import_bathy script
% bathy   = load([mod_dir 'cela.txt']);
bathy = Zq;


% Plots the bathymetry
figure; pcolor(bathy); shading interp; colorbar; title('measured bathymetry'); 
figure; surf(bathy); shading interp; colorbar; title('measured bathymetry [m]'); 

%% **Preparing Simulation Transect**
% Define endpoints of the transect you want to simulate
% You'll decide what coordinates to use after you plot the figure
x1 = 1200; % example number, replace with your own
y1 = 1400; % example number, replace with your own
x2 = 1200; % example number, replace with your own
y2 = 700; % example number, replace with your own

% Generate points along the line
numberOfPoints = 700; % Change to increase or decrease resolution

xPoints = linspace(x1,x2,numberOfPoints);
yPoints = linspace(y1,y2,numberOfPoints);

figure; pcolor(bathy); shading interp; colorbar; title('measured bathymetry [m]'); hold on;
plot([x1 x2], [y1 y2],'r'); 

% Interpolate bathymetry values along the transect

% Perform interpolation safely
bathymetryValues = interp1(1:size(bathy, 1), bathy(:, xPoints), yPoints, 'linear', 'extrap');

% Plot the bathymetry values along the transect
figure;
plot(1:numberOfPoints,bathymetryValues);
xlabel('Distance along transect');
ylabel('Bathymetry Values');
title('Transect of Bathymetry');

%% Wave Behavior
Hm0 = 1.0; % Significant wave height
Tp = 5.0; % Wave period
mainang = 90; % Direction the waves are coming from

% There are more advanced parameters stored in the jonswap script
% In most cases, leaving them at the default is fine

run('create_jonswap.m')

% Storm surge level
zs0 = -1

%% Defining Grid Size
% Grid resolution - best not to change if you don't have to
dxmin = .5
nx = 100
ny = 1
dx = 1
dy = 1

% Makes new grid vectors
x = [0:1:nx-1]*dx;
y = [0:1:ny-1]*dy;
z = bathymetryValues; 


[xg, yg] = meshgrid(x,y);
zg = repmat(z,length(y),1);

% This command resizes the grid to the new resolution. Can be removed
% later?

[xgr zgr] = xb_grid_xgrid(x,z,'dxmin',dxmin,'Tm',(Tp/1.2),'wl',zs0,'nonh',0,'ppwl',20);

 yy = xb_grid_ygrid(y,'dymin',15,'dymax',25,'area_type','center','area_size',0.5)
% We don't need a y-grid since we're using a profile, but we can keep the
% code in case we decide to cover a 2D area

bathymetry = xb_grid_add('x', x, 'z', z,'posdwn',1);

%% Pretty standard setting generation
pars = xb_generate_settings('xori',0,'yori',0,...                                   % grid stuff
                                'wavemodel', 'surfbeat', 'morphology',0,'sedtrans',0,... % physical processes
                                'wbctype','parametric','bcfile','jonswap.txt',...   % wave boundary
                                'outputformat','netcdf',...                         % don't change this 
                                'nglobal',{'zs','u','hh','H','zb'},'tintg',300,...  % variable to be globally output
                                'npoints',{'100 1','550 1'},'npointvar',{'zs','u','zb'},'tintp',10,... % specific points for time series
                                'nmeanvar',{'zs','u','H'},'tintm',360,...              % list mean variables to record
                                'order',1,...                                       % should be 1 or 2. 1 is less accurate but faster
                                'zs0',zs0,...
                                'rt', 7200, 'tstart',0,'tstop',7200);             % time management


% Merge the structures
xbm_si = xs_join(bathymetry, pars);

% Writing the model input file and saving in the directory
copyfile(mod_dir, destout);
xb_write_input([destout,'\params.txt'],xbm_si);
