clear all;
c = 3e8;
p = 0.1;
%% Initialize JDSU SWS15101 Tunable Laser
laser = gpib('ni',0,10);
laser.InputBufferSize = 5e6;
laser.OutputBufferSize = 5e6;
fopen(laser);
%clrdevice(laser);
set(laser,'TimeOut',1);

%% Initialize Power Meters
% Input
pm1 = gpib('ni',0,5);
pm1.InputBufferSize = 5e6;
fopen(pm1);
set(pm1,'TimeOut',1);
fprintf(pm1,'C');
fprintf(pm1,'W1550');

% Output 1
pm2 = gpib('ni',0,7);
pm2.InputBufferSize = 5e6;
fopen(pm2);
set(pm2,'TimeOut',1);
fprintf(pm2,'C');
fprintf(pm2,'W1550');

% Output 2
pm3 = gpib('ni',0,8);
pm3.InputBufferSize = 5e6;
fopen(pm3);
set(pm3,'TimeOut',1);
fprintf(pm3,'C');
fprintf(pm3,'W1550');

%% Setting laser parameters
pause on;

set(pm1,'TimeOut',1);
fprintf(pm1,'C');  pause(p);
fprintf(pm1,'W1550');

set(pm2,'TimeOut',1);
fprintf(pm2,'C');  pause(p);
fprintf(pm2,'W1550'); pause(p);

set(pm3,'TimeOut',1);
fprintf(pm3,'C');  pause(p);
fprintf(pm3,'W1550'); pause(p);

set(laser,'TimeOut',1);
fprintf(laser,'l=1550'); pause(p);
fprintf(laser,'p=1'); pause(p);
fprintf(laser,'enable'); pause(p);


%%
ld1 = 1540;  % start wavelength
ld2 = 1560;  % stop wavelength
step = 0.05;  % step wavelength
stime = 0.1;  % stop time

%fprintf(laser,'*SRE=6');  % To detect operation complete
fprintf(laser,['smin=',num2str(ld1)]);
fprintf(laser,['smax=',num2str(ld2+50*step)]);
fprintf(laser,['step=',num2str(step)]);
fprintf(laser,['stime=',num2str(stime)]);

N = ceil(abs(ld2-ld1)/step);

filename = ['e-tek_all_port1_',num2str(ld1),'-',num2str(ld2),'_step',...
    num2str(step*1000),'pm','.mat'];

%% Scanning and detecting power
clc;
pause on;

% clean output buffer from devices
progress = 0;
msg1 = ['Overall progress = ',num2str(ceil(progress*100)/100),...
    '%'];
msg2 = ['Cleaning devices'' buffers...'];
msg = {msg1; msg2};
wh = waitbar(0,msg,'Name','Sweeping wavelengths',...
            'CreateCancelBtn',...
            'setappdata(gcbf,''canceling'',1)');
setappdata(wh,'canceling',0);

% initialize data capturers
ld = zeros(N,1)*NaN;
power1 = zeros(N,1)*NaN;
power2 = power1;
power3 = power1;

% set the laser to start wavelength
fprintf(laser,['l=',num2str(ld1)]); pause(2);

% waitbar
progress = 0;
msg1 = ['Overall progress = ',num2str(ceil(progress*100)/100),...
    '%'];
msg2 = ['Time NA'];
msg = {msg1; msg2};
waitbar(progress, wh, msg);
allbreak = 0;

doneread = 1;
goon = 1;
count0 = 0;
count1 = 0; % to count how many read-from-device errors occur

% dump power meters buffers
devices = instrfind();
for i1=1:length(devices),
    if sum(devices(i1).PrimaryAddress == [5,6,7,8])>0,
        for i2=1:5,
            fprintf(devices(i1),'D?'); pause(p);
            dummy = fscanf(devices(i1)); pause(0.5);
        end
    end
    
    if devices(i1).PrimaryAddress == 10,
        for i2=1:5,
            fprintf(devices(i1),'L?'); pause(p);
            dummy = fscanf(devices(i1)); pause(0.5);
        end
    end
end
%}

fprintf(laser,'scan');
t0 = clock();
while goon==1,
    if getappdata(wh,'canceling'),
        allbreak = 1;
        break;
    end
    
    % send query commands
    fprintf(laser,'L?');
    fprintf(pm1,'D?');
    fprintf(pm2,'D?');
    fprintf(pm3,'D?');
    pause(p);
    
    % read from query
    dummy = fscanf(laser); pause(p);
    dummy1 = str2double(dummy(3:end));
    dummy = fscanf(pm1); pause(p);
    dummy2 = str2double(dummy);
    dummy = fscanf(pm2); pause(p);
    dummy3 = str2double(dummy);
    dummy = fscanf(pm3); pause(p);
    dummy4 = str2double(dummy);
    
    % check to recorde data or not
    if isnan(dummy1)==1 || (isnan(dummy2)==1 || isnan(dummy3)==1 || isnan(dummy4)==1),
        count1 = count1+1;
        pause(p);
        continue;
    end
    
    count0 = count0+1;
    if count0 > size(ld,1),
        dummy5 = zeros(N0,1);
        ld = [ld; dummy5];
        power1 = [power1; dummy5];
        power2 = [power2; dummy5];
        power3 = [power3; dummy5];
    end
    ld(count0) = dummy1;
    power1(count0) = dummy2;
    power2(count0) = dummy3;
    power3(count0) = dummy4;

    if dummy1>ld2,
        goon = 0;
        fprintf(laser,'stop');
        break;
    end
    
    % update figure
    fh1 = figure(1);
    x = 1:length(ld);
    plot(ld(x), power3(x));
    
    % waibar
    dldt = abs(ld2-ld1);
    dldn = abs(dummy1-ld1);
    dldl = abs(ld2-dummy1);
    progress = dldn/dldt;
    t1 = clock();
    totaltime = etime(t1,t0);
    timeleft = totaltime/dldn*dldl; % project remaining time, in seconds
    msg1 = ['Overall progress = ',num2str(ceil(progress*10000)/100),...
    '%'];
    msg2 = ['Remaining time = ', num2str(ceil(timeleft/60)),...
        ' min(s).'];
    msg = {msg1; msg2};
    waitbar(progress, wh, msg);
    pause(p);
end
if allbreak==1,
    fprintf(laser,'stop');
    disp('Canceled sweeping');
else
    disp('Done sweeping.');
end
delete(wh);
x = 1:count0;
ld = ld(x);
power1 = power1(x);
power2 = power2(x);
power3 = power3(x);

button = questdlg('Do you want to save?','Save data','Yes','No','Yes');
if strcmpi(button,'yes'),
    save(filename,'ld','power1','power2','power3','step');
end

pause off;
%fprintf(laser,'disable');