function spiketrain=timestamps_to_spiketrain(timestamps,category,length_of_trial)

%%%% this function converts  a list of spike times (which are
%%%% integers) into a spike train (list of 0s and 1s).  Resolution= 1 ms

    if nargin==1
        category=input('Do you want to turn spike times into spike trains, or vice versa?  type "trains" if you want trains, "times" if you want times ');
    else
    end

    if strcmp(category,'trains')

        if nargin==3  %%% only look at spike times before a certain time, denoted by length_of_trial
                spiketrain=zeros(size(timestamps,1),round(length_of_trial));

        else
                spiketrain=zeros(size(timestamps,1),max(max(round(timestamps))));

        end

            for i=1:size(timestamps,1);

                    spiketrain(i,round(timestamps(i,:)*1000))=1;

            end
    elseif strcmp(category,'times')

        %%%% implement this later
    else

        error('wrong input!')

    end


end