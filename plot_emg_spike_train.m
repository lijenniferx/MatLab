%% Below is a MatLab demo to illustrate the use of 'get_data', 'burst_features', and 'get_gapes'

%% Plotting EMG activity for 10 deliveries of 1 mM quinine (uses 'get_data')

filename='120530jxl36.nex'; % data file
data=get_data(0,filename); % extracts EMG activity


figure(1)
time=[-1500:1:2600];
emg=data.emg_data;

for trials = 1:29
    plot(time,emg{4}(trials,:)+(trials-1)*-1000,'k')
    text(-1000,(trials-1)*-1000+90,strcat('Delivery ',num2str(trials)),'fontsize',14,'BackgroundColor',[0.7,0.9,0.7])
    hold on

end
    ylim([(trials)*-200 200])
    xlim([-1500 2600])
    set(gca,'Ytick',[])
    xlabel('Time relative to taste delivery (ms)','fontsize',14)
    set(gca,'Fontsize',14)


   
%% Picking out individual movements within a single EMG response (uses 'burst_features')

emg=data.emg_data;
features=burst_features(emg{4});

% plotting EMG activity for a single delivery of 1 mM quinine
figure(2)
time=[-1500:1:2600];
whichtrial=10;
plot(time,emg{4}(whichtrial,:),'k')
hold on
xlim([-100 2400])
set(gca,'Ytick',[])
xlabel('Time relative to taste delivery (ms)','fontsize',14)
set(gca,'Fontsize',14)

% plotting movement peaks (in red)
plot(features{1}{whichtrial}(:,1)-1500,features{1}{whichtrial}(:,2),'r.','markersize',20)  
xlim([-100 2400])

% plotting movement onset (in yellow)
plot(features{1}{whichtrial}(:,5)+features{1}{whichtrial}(:,1)-1500,0,'y.','markersize',20)  
xlim([-100 2400])

% plotting movement offset (in cyan)
plot(features{1}{whichtrial}(:,6)+features{1}{whichtrial}(:,1)-1500,0,'c.','markersize',20)  
xlim([-100 2400])



%% Identifying gapes within a single EMG response (uses 'get_gapes')
% Here, I've colored the EMG bursts corresponding to gapes in red. 
gape_array = get_gapes(emg{4});

figure(4)
plot(emg{4}(whichtrial,:),'k')
hold on
gapetimes=find(gape_array{1}(whichtrial,:));
gape_indices=find(ismember(features{1}{whichtrial}(:,1),gapetimes));

for x=gape_indices'
    onset=features{1}{whichtrial}(x,1)+features{1}{whichtrial}(x,5);
    offset=features{1}{whichtrial}(x,1)+features{1}{whichtrial}(x,6);
    
    plot([onset:1:offset],emg{4}(whichtrial,onset:offset),'r')
end
xlim([1500 3900])
set(gca,'XTickLabel',{'0','500','1000','1500','2000'})
xlabel('Time relative to taste delivery (ms)','fontsize',14)
set(gca,'Fontsize',14)
set(gca,'Ytick',[])

