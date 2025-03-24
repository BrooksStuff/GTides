clear all
close all

% Adds OET
run('C:\Users\middl\OneDrive\Documents\Desktop\OET\oetsettings')

% Sets model directory and output
mod_dir = 'C:\Users\middl\OneDrive\Documents\Desktop\Matlab Designer Toolbox\Models\clean\';
destout = 'C:\Users\middl\OneDrive\Documents\Desktop\Sim Results\1\Terraces\';
data = 'C:\Users\middl\OneDrive\Documents\Desktop\Matlab Designer Toolbox\';
cd(data)

bathy = readmatrix([mod_dir 'cela2.csv']);
x1 = bathy(:, 3);
y1 = bathy(:, 4);
z1 = bathy(:, 2);

xq = unique(x1);
yq = unique(y1);
[Xq, Yq] = meshgrid(xq, yq);
Zq = griddata(x1, y1, z1, Xq, Yq, 'cubic');

min_elev = -12;
max_elev = 4;
mask = (Zq < min_elev | Zq > max_elev);
Zq(mask) = NaN;
Zq = fillmissing(Zq, 'nearest');

% Plots the bathymetry
figure; pcolor(Zq); shading interp; colorbar; title('measured bathymetry');

% We can use the previous plot to determine where we want the transect
% endpoints to be

% Define endpoints of transect line
x1 = 400;

y1 = 1400;

x2 = 400;

y2 = 700;

% Generate points along the line
numberOfPoints = 700;

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
Hm0 = 1;

Tp = 5.66;

mainang = 90;

% I can't find where this writes its data in the parameters document, but
% it IS important. The mainang here has to match the jonswap file too.
xb_wav = xb_generate_waves('Hm0',Hm0,'Tp',Tp,'duration',3600,'mainang',mainang);

% Storm surge level
zs0 = 0;

% All of the fun grid information that I love so much
dxmin = 1;

nx = numberOfPoints;

ny = 1;

dx = 1;

dy = 1;

% Defining the grid vectors... again
x = [0:1:nx-1]*dx;
y = [0:1:ny-1]*dy;
z = bathymetryValues +2;

[xg, yg] = meshgrid(x,y);
zg = repmat(z,length(y),1);

% Optimising the grid - this is done and actually works fine now
[xgr, zgr] = xb_grid_xgrid(x,z,'dxmin',dxmin,'Tm',(Tp/1.2),'wl',zs0,'nonh',1,'ppwl',40);

% Ignore this for now
% yy = xb_grid_ygrid(y,'dymin',15,'dymax',25,'area_type','center','area_size',0.5);

% Comparing original bed to new. If you are not making modifications to the
% existing bed, ignore this figure. 
figure;
plot(x,bathymetryValues,'b*');hold on;
plot(xgr,zgr,'r-o');hold on; title('cross-shore grid')  
legend('Original bed level','Model bathymetry')

% Shows varying resolution based on dx and dy that were specified earlier.
% Will be a flat line if resolution is constant.
figure;
plot(xgr(1:(end-1)),diff(xgr));title('cross-shore grid resolution')

bathymetry = xb_grid_add('x', xgr, 'z', zgr,'posdwn',1);

%% Had this in a previous script but haven't tested the integration yet.
% Meshgrid works as well
% [xq,yq] = meshgrid(xx,yy);

% bathy_2 = interp2(x,y,bathy,xg,yg);

% Finalising the grid
% [x y z] = xb_grid_finalise(xg,yg,bathy,xq,yq,'actions',{'lateral_extend','seaward_extend'},'n',5,'zmin',-15,'slope',1/50);

% Making a structure for the bathymetry
% bathymetry = xb_grid_add('x', xPoints, 'z', BathymetryValues,'posdwn',1);

%% Setting generation
pars = xb_generate_settings('xori',0,'yori',0,...                                   % grid stuff
                                'wavemodel', 'surfbeat', 'morphology',0,'sedtrans',0,... % physical processes
                                'wbctype','parametric','bcfile','jonswap.txt',...   % wave boundary
                                'outputformat','netcdf',...
                                'nglobal',{'zs','H','zb'},'tintg',300,...  % global output
                                'nmeanvar',{'zs'},'tintm',3600,...              % mean variables
                                'order',2,...                                       & only first order steering to speedup!
                                'zs0',zs0,...
                                'dy',dy,...
                                'rt', 3900, 'tstart',0,'tstop',36000);             % time management


% Merge the structures
xbm_si = xs_join(bathymetry, pars);

% Writing the model input file and saving in the directory
xb_write_input([destout,'\params.txt'],xbm_si);

% Directory saving information. Make sure they are different and not
% nested. 
%mkdir(destout)
%copyfile(mod_dir, destout);
