function cleaned_up_events=removing_bad_events(key_events)
    
    %%%% this function was written to remove "fake" TTL pulses caused by
    %%%% hardware issues

    for xx=1:numel(key_events)
           number_of_deliveries(xx)=length(key_events{xx});
    end
       
    
    if mean(number_of_deliveries)==number_of_deliveries(1);
            cleaned_up_events=key_events;
            return
    else
    end
        
    %%%%%  going through the procedure of identifying and eliminating extra
    %%%%%  event times
    
    all_events=[];
    for xx=1:numel(key_events)
        all_events=cat(1,all_events,key_events{xx});
    end
    all_events=sort(all_events);
    
    
    potentially_bad_events=find(diff(all_events)<15000);
    
    
    %%%% one bad event jammed in between two closely separated bad events:
    %%%% this produces two short ISI
    close_bad_events=all_events(potentially_bad_events(find(ismember(potentially_bad_events-1,potentially_bad_events))));  %%% finding consecutive faulty ISIs, taking the latter ones.
    
    all_events=setxor(all_events,close_bad_events);
    all_events=sort(all_events);
    
    %%% one bad event jammed in between two widely separated bad events
    
    far_bad_events=all_events(find(diff(all_events)<15000)+1);  %%% finding isolated faulty ISIs
    
    all_events=setxor(all_events,far_bad_events);
    
    %%%% putting the events back
    for xx=1:numel(key_events)
        cleaned_up_events{xx}=intersect(key_events{xx},all_events);
    end
    
    
end
    
    
    
    