function output_array=make_spike_arrays(tastes,spike_train,prestimulus_time,poststimulus_time)
%%% this function converts a spike train (__spike_train__: long list of 0s and 1s) into multiple arrays,
%%% where each array is the spike activity around the delivery of a given taste (specified by __tastes__). 

%%%% __prestimulus_time__: how much time BEFORE the taste delivery do you want to include?
%%%% __poststimulus_time__: how much time AFTEr the taste delivery do you want to include?


            for taste=1:size(tastes,2)
    
                for trial=1:length(tastes{taste})

                    output_array{taste}(trial,:)=spike_train(tastes{taste}(trial)-prestimulus_time:tastes{taste}(trial)+poststimulus_time);
                end
            end
end
