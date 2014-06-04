%%%%% getting rid of certain rows in a matrix

function output_matrix=remove_rows(input_matrix,rows_to_be_removed)

%%% syntax of rows_to_be_removed: [2 9]

    output_matrix= input_matrix(~ismember(1:size(input_matrix, 1), rows_to_be_removed), :);
    
    
end