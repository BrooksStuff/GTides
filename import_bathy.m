close all;
clear all;

mod_dir = 'C:\Users\middl\OneDrive\Documents\';

%% **Reading the elevation data**
% Identifies the x, y, and z values of each point based on columns in the
% elevation data
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
        % Define neighborhood bounds
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

%% **Visualize the Adjusted Grid in a Surface Plot**
figure;
surf(Xq, Yq, Zq);
shading interp;
colorbar;
title('3D Terrain Visualization');
xlabel('x [ft]');
ylabel('y [ft]');
zlabel('z [ft]');

%% **Visualize the Adjusted Grid in a pcolor Plot**
figure;
pcolor(Xq, Yq, Zq);
shading interp;
colorbar;
title('Site DEM');
xlabel('x [ft]');
ylabel('y [ft]');
zlabel('z [ft]');

%% **Exporting the new terrain**
% The matrix is the only part of this that is necessary for a simulation,
% but this can also generate an object file for you to use in graphics
writematrix(bathy, fullfile(mod_dir, 'cela.txt'));


% Prepare for triangulation and STL export
%vertices = [Xq(:), Yq(:), Zq(:)];
%tri = delaunay(vertices(:, 1), vertices(:, 2));
%tri_obj = triangulation(tri, vertices);

% Export to STL
%output_file = fullfile(mod_dir, 'new.stl');
%stlwrite(tri_obj, output_file);
%disp(['STL file saved as ', output_file]);