%%%% this function takes a vector 'a', and an index point within that vector,
%%%% and identifies the continuous members of the vector around that index
%%%% point that are larger or smaller than a set value 'b'

function [qualifying_values, qualifying_indices]=falls_between(a,index,b,smaller_or_larger)

    if smaller_or_larger==1 %%%% then want members of 'a' that are larger than 'b'
   
        %%%% going to the left of index
        good_indices=[];
        left=1;
        while (index-left)>1
            
            if a(index-left)>b
                good_indices=cat(1,good_indices, index-left);
            else
                break
            end
            left=left+1;
        end
        %%%%%%%%%
        
        %%%% going to the right of index
        right=0;
        while (index+right)<length(a)
           
            if a(index+right)>b
                good_indices=cat(1,good_indices, index+right);
            else
                break
            end
            right=right+1;
        end
        %%%%%%%%%
        
    else
        
        
        %%%% going to the left of index
        good_indices=[];
        left=1;
        while (index-left)>1
            
            if a(index-left)<b
                good_indices=cat(1,good_indices, index-left);
            end
            left=left+1;
        end
        %%%%%%%%%
        
        %%%% going to the right of index
        right=0;
        while (index+right)<length(a)
           
            if a(index+right)<b
                good_indices=cat(1,good_indices, index+right);
                
            end
            right=right+1;
        end
        %%%%%%%%%
        
        
    end
    qualifying_values=a(sort(good_indices));
    qualifying_indices=index-sort(good_indices);
end