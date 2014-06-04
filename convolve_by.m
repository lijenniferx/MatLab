function result=convolve_by(thingtobeconvolved,window)
% CONVOLVE_BY smooths a vector with a rectangular filter, trims off the ends, and returns the output
% 
% INPUTS
% __thingtobeconvolved:     1d vector of numbers
% __window:                 An integer specifying the length of the rectangular filter


    if window==1
        
        result=thingtobeconvolved;
        
    elseif isempty(thingtobeconvolved)
        
        result=[];
    
    else

         for i=1:size(thingtobeconvolved,1)
                %%% performing the convolution
             temporaryresult(i,:)=conv(full(thingtobeconvolved(i,:)),ones(1,window));
                
                %%%% trimming off the ends
             result(i,:)=temporaryresult(i,round(window/2):end-round(window/2));
         end
    end
end
