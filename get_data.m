% GET_DATA: extracts neural and emg data from (.nex) experiment file (Plexon Inc.), and
%           performs some simple processing to remove errors and movement artifacts.
%
%   This function produces:
%   1. arrays consisting of milliseconds of spike trains and muscle responses before and after each taste delivery
%   2. timestamps of taste deliveries
%   3. indices of retained taste deliveries 
%   4. list of trials in which lasers were turned ON
%
% INPUTS
% __filename:        A string, ex: '120704jxl40.nex', that specifies the raw data file
% __issorted:       '1'- want spike train data
%                   '0'- do not want spike train data 
% __unitnumbers_take (optional):  a vector of neuron IDs to exclude.  The default value is []
% __pre (optional):  Amount of time preceding each taste delivery to extract (in ms)
% __post (optional): Amount of time after each taste delivery to extract (in ms)
%
%
% OUTPUTS 
% __data:            A data structure containing arrays of spike trains (binary) and EMG responses (continuous).
%                    Values can be accessed as follows: data.emg_data{1}, to get the EMG responses for the first
%                    taste stimulus. For each array, row x column = trials x time (ms)
% __useful_events:   A cell array consisting of taste delivery timestamps. Can be broken down into useful_events{1}, etc, to get the
%                    timestamps for the first taste stimulus. 
%__final_trials:     A cell array consisting of the indices of taste
%                    deliveries with detectable EMG. Deliveries were
%                    retained if the animal produced a detectable EMG response. 
%                    where the animal produced a detectable EMG response. 
%
% NOTES
%                   Spiking and EMG data are stored in separate .nex files  
%                   Spiking data: '120704jxl40-interval.nex'
%                   EMG data: '120704jxl40.nex'
%
% HELPER FUNCTIONS
% __readNexData():                Reads the binary .nex file and puts the data into a structure (written by Plexon, Inc)
% __removing_bad_events():        Removes some fake events due to hardware problems
% __keep_significant_response():  Returns a vector of trials where the taste induced a sufficiently large EMG response
% __timestamps_to_spiketrain():   Converts spike times into a list of 0s and 1s, where 1 corresponds to the occurrence of a spike (resolution: 1 kHz)
% __make_spike_arrays():          Indexes the full spike train by the taste delivery times, and organizes the result 
%                                 into arrays where (row x column) = (trial x time)

%%%%%%%%%%%%% Written by: Jennifer Li 


function [data,useful_events,final_trials,laser_on]=get_data(issorted,filename, unitnumbers_take, pre, post)
 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% ADJUSTABLE PARAMETERS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%% checking input parameters and setting time intervals of interest

    
    if nargin==2
        unitnumbers_take=[];
        prestimulus_time=1500;   
        poststimulus_time=2600;
    else
        unitnumbers_take=unitnumbers_take;
        prestimulus_time=pre;  %%% how much time before taste delivery do you want?
        poststimulus_time=post;  %%% how much time after taste delivery do you want?
        
    end 

    
%%%% Gets the structure array from the .nex file for the EMG data
    filename_emg=filename;  
    
    template='\d\d\d\d\d\d\w+\d+[.nex]';
    if isempty(regexp(filename,template,'ONCE'))
        error('You did not enter an acceptable filename.  It needs to look like 130506jxl36.nex or 130506x10.nex.')
    end

    if length(filename)==15
        whichrat=strcat(strcat('JXL',filename(10:11)),'/');
        path2=strcat('/Users/jenniferli/Desktop/KatzLabProjects/Data/',whichrat);
        path=strcat(path2,filename(1:end-4));
        cd(path)
    elseif length(filename)==13
        whichrat=strcat(strcat('X',filename(8:9)),'/');
        path2=strcat('/Users/jenniferli/Desktop/KatzLabProjects/Data/',whichrat);
        path=strcat(path2,filename(1:end-4));
        cd(path)
    else
        error('You did not enter an acceptable filename. It needs to look like 130506jxl36.nex or 130506x10.nex.')
    end
        


    important_data=readNexFile(filename_emg);
    
    
    %%% time offset for continuous data. The 'clock' for the continuous channels 
    %%% starts after the 'clock' for the digital channels and events.
    deadtime=round(important_data.contvars{1}.timestamps*1000);  

%%%%% resampling and filtering parameters for EMG signal. 

    emg_port='AD17';  
    downsampling_rate=1000; %%%% downsampling EMG signal to 1kHz
    bandpass_frequencies=[300 499.99];  %%%% specifices the frequencies of the EMG signal that you want to keep
    bandpass_convert=bandpass_frequencies/downsampling_rate*2;  %%%% convert the bandpass frequencies to inputs for the butterworth filter
    [a,b]=butter(2,bandpass_convert);  %%% high bandpass the EMG data to get rid of movement artifact
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
%%%% pulling out timestamps for the individual taste events
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    


    taste_events=important_data.events;
    bottle_event={{} {} {} {} {}};  %%% 5 bottles are possible
    key_events={};
    laser_events=0;
    
    for i=1:length(taste_events)-2
        if taste_events{i}.name=='Event003';   %%%% 0.03 M sucrose 
            bottle_event{1}=round(taste_events{i}.timestamps*1000);  
        elseif taste_events{i}.name=='Event004';  %%% 0.3 M sucrose 
            bottle_event{2}=round(taste_events{i}.timestamps*1000);
        elseif taste_events{i}.name=='Event005';  %%%% 0.0001 M quinine
            bottle_event{3}=round(taste_events{i}.timestamps*1000);
        elseif taste_events{i}.name=='Event006';  %%%% 0.001 M quinine
            bottle_event{4}=round(taste_events{i}.timestamps*1000); 
        elseif taste_events{i}.name=='Event008';  %%% 1% saccharin
            bottle_event{5}=round(taste_events{i}.timestamps*1000);
            
        %%% To get the laser events 
        elseif taste_events{i}.name=='Event014';  
            laser_events=round(taste_events{i}.timestamps*1000);
        
        end
     
    end
 
    
    %%%%% retaining event timestamps for taste channels that were used in the experiment
     index=1;
     for i=1:length(bottle_event)
        if numel(bottle_event{i})>10 %%% keep channels with more than 9 timestamps
            key_events{index}=bottle_event{i};
            index=index+1;
        else
            key_events=key_events;
        end
     end
     
     %%%%% getting rid of fake event timestamps due to bug in hardware
     key_events=removing_bad_events(key_events);
     
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
%%%%%% Resampling EMG response to 1 kHz, converting uV into mV
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 

    
    %%% GETTING THE CONTINUOUS CHANNEL FOR THE EMG DATA
    
    for i=1:size(important_data.contvars,1)
        
        
        if min(important_data.contvars{i}.name==emg_port);
            emg_channel=i;
        end
      
    
    end

    
    %%% Resampling the EMG data 
    

    if (str2num(filename(1:2))==12&&str2num(filename(4))<8)|...
            (sum(filename(4:6)=='529')==3)|(sum(filename(4:6)=='618')==3)|...
            (sum(filename(4:6)=='619')==3)  
        %%%% for some files, sampling rate was accidentally set at 2.5 kHz
        
        downsampled_emg=resample(important_data.contvars{emg_channel}.data,downsampling_rate,2500);  
               
    else 
        %%%% for remaining files, sampling rate was correctly set at 1 kHz
        
        downsampled_emg=important_data.contvars{emg_channel}.data;
            
                
    end

    %%% incorporating the deadtime
    downsampled_emg=cat(1,zeros(deadtime,1),downsampled_emg);
    
    %%% converting EMG signals from mV to uV;
    
        downsampled_emg=downsampled_emg*1000;  
        
        
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%   
%%%% 1. Extracts desired portions EMG response [prestimulus_time:poststimulus_time] relative to taste delivery 
%%%% 2. Extracts and concatenates baseline measurements [pre:0]
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    emg_baseline=[];
    for taste=1:size(key_events,2)  %%% looping through each taste
    
        for trial=1:length(key_events{taste}) %%% looping through each trial
            
                start=key_events{taste}(trial)-prestimulus_time;
                stop=key_events{taste}(trial)+poststimulus_time;
           
                emg_data{taste}(trial,:)=filtfilt(a,b,downsampled_emg(start:stop));%%% bandpass filtering EMG data according to specifications
                emg_baseline=cat(2,emg_baseline,abs(emg_data{taste}(trial,1:prestimulus_time)));
        
        end
    
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% Identify the trials where the taste elicited a sufficiently large EMG response
%%%% 1. the mean response is less than the 1x the mean of the baseline response (emg_baseline)
%%%% 2. and the max is larger than mean(emg_baseline)+4*std(emg_baseline)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    trials_with_emg=keep_significant_response(key_events,emg_data,emg_baseline,prestimulus_time);
     

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% GETTING NEURAL/SPIKING DATA %%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


    if issorted==0
        final_spikes=[];  %%% didn't want to get get spiking data
    else
        
            
        %%%% Gets the structure array from the .nex file for the neural data
        

        filename_neural=strcat(filename(1:end-4),'-interval.nex'); 
        important_data_neural=readNexFile(filename_neural);
        unitnumbers=[1:size(important_data_neural.neurons,1)];

        if isempty(unitnumbers_take)%%%% take all neurons
            unitnumbers_take=[1:size(important_data_neural.neurons,1)];
        else
            unitnumbers_take=unitnumbers_take; %%% choose according to specifications to avoid analyzing duplicate neurons
        end


    
       %%%% Converts spike times to spike trains
    
        neurons={};
        for unit=unitnumbers_take %% looping through all of the neurons
        
            neurons=cat(1,neurons,important_data_neural.neurons{unit});
            spike_trains{unit}=timestamps_to_spiketrain(neurons{unit}.timestamps','trains',round(important_data.tend*1000));
            
            %%%%% organizing spike trains into cell arrays:
            %%%%% final_spikes{unit_id}{taste} is an array with dimensions (trial x time)

            final_spikes{unit}=make_spike_arrays(key_events,spike_trains{unit},prestimulus_time,poststimulus_time);
    
        end

    
    end

    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% Generating the output variables: 
%%%% "data", "useful_events",and "final_trials" 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    for tastes=1:length(key_events)
        useful_events{tastes}=key_events{tastes}(trials_with_emg{tastes},:);
        data.emg_data{tastes}=emg_data{tastes}(trials_with_emg{tastes},:);
        final_trials{tastes}=trials_with_emg{tastes};
        
            for unit=1:length(final_spikes)
                data.neural_data{unit}{tastes}=final_spikes{unit}{tastes}(trials_with_emg{tastes},:);
            end
        
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%% getting the taste deliveries where the lasers were turned ON
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    clear laser_on
    %%% 
    for taste=1:length(key_events)  %%% go through each taste
    
        %%% GO THROUGH TRIALS WITH DETECTABLE EMG
        for trials=1:length(useful_events{taste}) 
            
            if mean(laser_events)==0 %%%% not an optogenetics expt
                laser_on{taste}(trials)=0;
            elseif min(abs(useful_events{taste}(trials)-laser_events))<400;  %%% pick out taste deliveries that were accompanied with laser
                laser_on{taste}(trials)=1;
            else
                laser_on{taste}(trials)=0;
            end
        end
        
        
    end
    

 
end


