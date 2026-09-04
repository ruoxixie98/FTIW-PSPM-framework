function connectivity_dict = build_connectivity_dictionary(max_dim, distance_power)
% Distance weights for 26-neighbour windows.

fprintf('Preparing local connectivity...\n');
connectivity_dict = containers.Map;

for dim_x = 1:max_dim(1)
    for dim_y = 1:max_dim(2)
        for dim_z = 1:max_dim(3)
            n_points = dim_x * dim_y * dim_z;
            max_edges = min(26 * n_points, n_points ^ 2);
            conn_matrix = spalloc(n_points, n_points, max_edges);

            for z = 1:dim_z
                for y = 1:dim_y
                    for x = 1:dim_x
                        current_idx = sub2ind( ...
                            [dim_x, dim_y, dim_z], x, y, z);

                        for dz = -1:1
                            for dy = -1:1
                                for dx = -1:1
                                    if dx == 0 && dy == 0 && dz == 0
                                        continue;
                                    end

                                    xn = x + dx;
                                    yn = y + dy;
                                    zn = z + dz;
                                    if xn < 1 || yn < 1 || zn < 1 || ...
                                            xn > dim_x || ...
                                            yn > dim_y || zn > dim_z
                                        continue;
                                    end

                                    neighbor_idx = sub2ind( ...
                                        [dim_x, dim_y, dim_z], xn, yn, zn);
                                    distance = sqrt(dx ^ 2 + dy ^ 2 + dz ^ 2);
                                    if distance_power == 0
                                        weight = 1;
                                    else
                                        weight = 1 / distance ^ distance_power;
                                    end
                                    conn_matrix(current_idx, neighbor_idx) = ...
                                        weight; %#ok<SPRIX>
                                end
                            end
                        end
                    end
                end
            end

            key = sprintf('%dx%dx%d', dim_x, dim_y, dim_z);
            connectivity_dict(key) = conn_matrix;
        end
    end
end
end
