clear all
close all

% Adds OET
run('C:\Users\middl\OneDrive\Documents\Desktop\OET\oetsettings')

% Sets model directory and output
mod_dir = 'C:\Users\middl\OneDrive\Documents\Desktop\Matlab Designer Toolbox\Models\clean\';
destout = 'C:\Users\middl\OneDrive\Documents\Desktop\Matlab Designer Toolbox\Models\myrun\';
data = 'C:\Users\middl\OneDrive\Documents\Desktop\Matlab Designer Toolbox\';
cd(data)

bathy = readmatrix([mod_dir 'cela1.csv']);
x1 = bathy(:, 3);
y1 = bathy(:, 4);
z1 = bathy(:, 2);

xq = unique(x1);
yq = unique(y1);
[Xq, Yq] = meshgrid(xq, yq);
Zq = griddata(x1, y1, z1, Xq, Yq, 'cubic');

min_elev = -12;
max_elev = 0;
mask = (Zq < min_elev | Zq > max_elev);
Zq(mask) = NaN;
Zq = fillmissing(Zq, 'nearest');


% Plots the bathymetry
figure; pcolor(Zq); shading interp; colorbar; title('measured bathymetry');

% We can use the previous plot to determine where we want the transect
% endpoints to be

% Define endpoints of transect line
prompt = "x1: ";
x1 = input(prompt);

prompt = "y1: ";
y1 = input(prompt);

prompt = "x2: ";
x2 = input(prompt);

prompt = "y2: ";
y2 = input(prompt);

% Generate points along the line
prompt = "numberOfPoints: ";
numberOfPoints = input(prompt);
xPoints = linspace(x1,x2,numberOfPoints);
yPoints = linspace(y1,y2,numberOfPoints);

% Interpolate bathymetry values along the transect
bathymetryValues = interp2(Zq,xPoints,yPoints);

% Plot the bathymetry values along the transect
figure;
plot(1:numberOfPoints,bathymetryValues);
xlabel('Distance along transect');
ylabel('Bathymetry Values');
title('Transect of Bathymetry');

% Defining wave conditions
% prompt = "Hm0: ";
Hm0 = 1
% input(prompt);

% prompt = "Tp: ";
Tp = 5.66
% input(prompt);

% Save wave input in XBeach structure
% I don't recall seeing any of this actually appear in params, nor does it
% generate a jonswap file, so I wrote one myself manually, following these
% parameters. This means the preceding inputs are technically useless, but
% go ahead and act like they aren't just in case I missed something.
xb_wav = xb_generate_waves('Hm0',Hm0,'Tp',Tp,'duration',3600,'mainang',90);

% Storm surge level
% prompt = "zs0: ";
zs0 = 0
% input(prompt);

% All of the fun grid information that I love so much
% prompt = "dxmin: ";
dxmin = 1
% input(prompt);

% prompt = "nx: ";
nx = numberOfPoints
% input(prompt);

% prompt = "ny: ";
ny = 1
% input(prompt);

% prompt = "dx: ";
dx = 1
% input(prompt);

% prompt = "dy: ";
dy = 1
% input(prompt);

% Defining the grid vectors... again
x = [0:1:nx-1]*dx
y = [0:1:ny-1]*dy
z = bathymetryValues +2

[xg, yg] = meshgrid(x,y);
zg = repmat(z,length(y),1);

% Optimising the grid - this is done and actually works fine now
[xgr zgr] = xb_grid_xgrid(x,z,'dxmin',dxmin,'Tm',(Tp/1.2),'wl',zs0,'nonh',1,'ppwl',40);

% yy = xb_grid_ygrid(y,'dymin',15,'dymax',25,'area_type','center','area_size',0.5)
% We don't need a y-grid since we're using a profile, but we can keep the
% code in case we decide to cover a 2D area

figure;
plot(x,bathymetryValues,'b*');hold on;
plot(xgr,zgr,'r-o');hold on; title('cross-shore grid')  
legend('Original bed level','Model bathymetry')
% It's not like there's really any change for it to show on a small scale,
% but it can be used to check if everything works alright I guess

figure;
plot(xgr(1:(end-1)),diff(xgr));title('cross-shore grid resolution')

bathymetry = xb_grid_add('x', xgr, 'z', zgr,'posdwn',1);

%% Don't need any of this stuff. It was copied from a few other scripts but contributed nothing necessary
% Meshgrid works as well
% [xq,yq] = meshgrid(xx,yy);

% bathy_2 = interp2(x,y,bathy,xg,yg);

% Finalising the grid
% [x y z] = xb_grid_finalise(xg,yg,bathy,xq,yq,'actions',{'lateral_extend','seaward_extend'},'n',5,'zmin',-15,'slope',1/50);

% Making a structure for the bathymetry
% bathymetry = xb_grid_add('x', xPoints, 'z', BathymetryValues,'posdwn',1);

%% Pretty standard setting generation
pars = xb_generate_settings('xori',0,'yori',0,...                                   % grid stuff
                                'wavemodel', 'surfbeat', 'morphology',0,'sedtrans',0,... % physical processes
                                'wbctype','parametric','bcfile','jonswap.txt',...   % wave boundary
                                'outputformat','netcdf',...
                                'nglobal',{'zs','u','hh','H','zb'},'tintg',300,...  % global output
                                'nmeanvar',{'zs','u'},'tintm',3600,...              % mean variables
                                'order',2,...                                       & only first order steering to speedup!
                                'zs0',zs0,...
                                'dy',dy,...
                                'rt', 3900, 'tstart',0,'tstop',36000);             % time management


% Merge the structures
xbm_si = xs_join(bathymetry, pars);

% Writing the model input file and saving in the directory
xb_write_input([destout,'\params.txt'],xbm_si);

% These never work for some reason but it also never stops the simulations
mkdir(destout)
copyfile(mod_dir, destout);
