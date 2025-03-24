clear all
close all

% Adds OET
run('C:\Users\middl\OneDrive\Documents\Desktop\OET\oetsettings')
mod_dir = 'C:\Users\middl\OneDrive\Documents\Desktop\Matlab Designer Toolbox\Models\clean\';
destout = 'C:\Users\middl\OneDrive\Documents\Desktop\Matlab Designer Toolbox\Models\myrun\';
data = 'C:\Users\middl\OneDrive\Documents\Desktop\Matlab Designer Toolbox\';
cd(data)

%% Data Import
bathy = readmatrix([mod_dir 'cela1.csv']);
x1 = bathy(:, 3);
y1 = bathy(:, 4);
z1 = bathy(:, 2);

% Creating a grid
xq = unique(x1);
yq = unique(y1);
[Xq, Yq] = meshgrid(xq, yq);
Zq = griddata(x1, y1, z1, Xq, Yq, 'cubic');

%% Cleaning Elevation Data
min_elev = -12;
max_elev = 0;
mask = (Zq < min_elev | Zq > max_elev);
Zq(mask) = NaN;
Zq = fillmissing(Zq, 'nearest');

figure; pcolor(Zq); shading interp; colorbar; title('measured bathymetry');

%% Define Transect
x_start = 1200; % Replace with actual start x
y_start = 1400; % Replace with actual start y
x_end = 1200;
y_end = 700;
num_points = 700;

x_transect = linspace(x_start, x_end, num_points);
y_transect = linspace(y_start, y_end, num_points);
z_transect = interp2(Xq, Yq, Zq, x_transect, y_transect, 'linear', NaN);

% Plot the transect
figure;
plot(1:num_points, z_transect, 'b');
xlabel('Distance along transect');
ylabel('Bathymetry (m)');
title('Transect Profile');

%% Wave and Storm Surge Parameters
Hm0 = 1.0;
Tp = 5.0;
mainang = 180; % Waves moving upward in +y direction
zs0 = -1;

%% Define Grid for 1D Profile Simulation
dxmin = 0.5;
nx = num_points;
ny = 1; % Force 1D profile

x = linspace(0, (nx-1)*dxmin, nx);
y = 0; % Single line for 1D model
z = z_transect;

%% Generate XBeach Input
tstop = 7200;
pars = xb_generate_settings('xori',0,'yori',0,...
    'wavemodel', 'surfbeat', 'morphology',0,'sedtrans',0,...
    'wbctype','parametric','bcfile','jonswap.txt',...
    'outputformat','netcdf',...
    'nglobal',{'zs','u','hh','H','zb'},'tintg',300,...
    'nmeanvar',{'zs','u','H'},'tintm',360,...
    'order',2,...
    'zs0',zs0,...
    'rt', 7200, 'tstart',0,'tstop',tstop);

bathymetry = xb_grid_add('x', x, 'z', z,'posdwn',1);
xbm_si = xs_join(bathymetry, pars);

copyfile(mod_dir, destout);
xb_write_input([destout,'\params.txt'],xbm_si);
