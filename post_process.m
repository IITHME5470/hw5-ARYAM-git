clc; clear all; close all;

base_dir = 'D:/8th Semester/ME5470 Introduction to Parallel Scientific Computing/hw5/hw5';

configs = struct('name', {'Serial', '2 × 2', '2 × 4', '4 × 4'}, ...
                 'folder', {'serial', 'nx2ny2', 'nx2ny4', 'nx4ny4'}, ...
                 'px', {1, 2, 2, 4}, 'py', {1, 2, 4, 4});

% Define time IDs
tids = [10, 2553, 5106];

nx = 800; ny = 800;
[X, Y] = meshgrid(linspace(-0.05, 1.05, nx), linspace(-0.05, 1.05, ny));

line_styles = {'-', '--', '-.', ':'};  

for tid = tids
    
    mid_profiles = cell(1, length(configs));
    
  
    figure('Position', [100 100 1600 400]); 
    tiledlayout(1, 4, 'TileSpacing', 'compact', 'Padding', 'none');
    sgtitle(sprintf('tid = %d', tid), 'Interpreter', 'latex', 'FontSize', 18);

    for c = 1:length(configs)
        folder = configs(c).folder;
        px = configs(c).px;
        py = configs(c).py;

        % Initialize global temperature array
        T_global = zeros(nx, ny);
        
        if px == 1 && py == 1  % Serial case
            file_path = fullfile(base_dir, folder, sprintf('T_x_y_%06d.dat', tid));
            a = dlmread(file_path);
            T_global = reshape(a(:,3), [ny, nx]);
        else  % Parallel cases
            nx_local = nx / px;
            ny_local = ny / py;

            for rank = 0:(px*py - 1)
                rank_y = floor(rank / px);
                rank_x = mod(rank, px);
                
                file_path = fullfile(base_dir, folder, sprintf('T_x_y_%06d_%04d.dat', tid, rank));
                a = dlmread(file_path);
                T = reshape(a(:,3), [ny_local, nx_local]); 

                x_start = rank_x * nx_local + 1;
                x_end = (rank_x + 1) * nx_local;
                y_start = rank_y * ny_local + 1;
                y_end = (rank_y + 1) * ny_local;

                T_global(x_start:x_end, y_start:y_end) = T';
            end
        end
        
        % Store mid-y temperature profile
        mid_profiles{c} = T_global(:, round(ny/2));

        % Plot contour
        nexttile
        contourf(X, Y, T_global', 'LineColor', 'none');
        xlabel('$x$', 'Interpreter', 'latex', 'FontSize', 14);
        ylabel('$y$', 'Interpreter', 'latex', 'FontSize', 14);
        title(configs(c).name, 'Interpreter', 'latex', 'FontSize', 14);
        xlim([-0.05 1.05]); ylim([-0.05 1.05]); caxis([-0.05 1.05]);
        colormap('jet');
        set(gca, 'FontSize', 14);
        axis square; 

     
        if c == length(configs)
            colorbar;
        end
    end
    
    saveas(gcf, sprintf('contours_tid_%06d.png', tid));

    figure('Position', [100 100 800 500]); hold on;
    for c = 1:length(configs)
        plot(linspace(-0.05, 1.05, nx), mid_profiles{c}, line_styles{c}, 'LineWidth', 2);
    end
    xlabel('$x$', 'Interpreter', 'latex', 'FontSize', 14);
    ylabel('$T$', 'Interpreter', 'latex', 'FontSize', 14);
    title(sprintf('Temperature Profile along $y=0.5$ for tid = %d', tid), ...
          'Interpreter', 'latex', 'FontSize', 14);
    legend(configs.name, 'Interpreter', 'latex', 'FontSize', 14, 'Location', 'best');
    ylim([0 1]); % Enforce y-axis limits to [0,1]
    xlim([0 1])
    set(gca, 'FontSize', 14);

    % Save line plot figure
    saveas(gcf, sprintf('line_profiles_tid_%06d.png', tid));
end

%%
% Load Serial Case Temperature Matrix
tid = 10;
a_serial = dlmread(sprintf('serial/T_x_y_%06d.dat', tid));
T_serial = reshape(a_serial(:,3), [800, 800]);

% Load Parallel 4x4 Case Temperature Matrix
a_parallel_4x4 = dlmread(sprintf('nx4ny4/T_x_y_%06d_%04d.dat', tid, 0)); % Load rank 0 file
T_parallel_4x4 = zeros(800, 800);

for rank = 0:15  
    rank_y = floor(rank / 4);
    rank_x = mod(rank, 4);
    
    a = dlmread(sprintf('nx4ny4/T_x_y_%06d_%04d.dat', tid, rank));
    
    nx_local = 800 / 4;
    ny_local = 800 / 4;
    
    T_local = reshape(a(:,3), [ny_local, nx_local]);
    
    x_start = rank_x * nx_local + 1;
    x_end = (rank_x + 1) * nx_local;
    y_start = rank_y * ny_local + 1;
    y_end = (rank_y + 1) * ny_local;
    
    T_parallel_4x4(x_start:x_end, y_start:y_end) = T_local';
end

max_diff = max(abs(T_serial(:) - T_parallel_4x4(:)));
t
fprintf('Max absolute difference: %e\n', tid, max_diff);
