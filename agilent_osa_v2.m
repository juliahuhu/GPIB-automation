clear;
c = 299792458;

osa = gpib('ni',0,23);
%% OSA Initialization
osa.InputBufferSize = 1000000;
fopen(osa);
fprintf(osa,'*RST');
fprintf(osa,'*OPC?');
fscanf(osa);

%% Set OSA Parameters
startLd = 1510;
stopLd = 1610;
resLd = 0.5;
ldPoints = round((stopLd-startLd))/resLd+1;
swpTime = 1000; %in ms
sensitivity = -80; %in dBm
fprintf(osa,'syst:comm:gpib:buff on');
fprintf(osa,['sens:wav:star ',num2str(startLd),'nm']);
fprintf(osa,['sens:wav:stop ',num2str(stopLd),'nm']);
fprintf(osa,['sens:bwid:res ',num2str(resLd),'nm']);
fprintf(osa,['sens:swe:poin ',num2str(ldPoints)]);
fprintf(osa,['sens:swe:time ',num2str(swpTime),'ms']);
fprintf(osa,['sens:pow:dc:rang:low ',num2str(sensitivity),'dbm']);
fprintf(osa,'*OPC?');
fscanf(osa);
%%
%MSGID='instrument:fscanf:unsuccessfulRead';
%warning('off',MSGID);
yi = [];
for i1=1:3,
    fprintf(osa,'init:imm;*OPC?');
    fscanf(osa);
    fprintf(osa,'form ascii');
    fprintf(osa,'trace:data:y? tra');
    yi = [yi,fscanf(osa,['%f',','])];
    fprintf(osa,'sens:wav:star?');
    ld1 = str2double(fscanf(osa));
    fprintf(osa,'sens:wav:stop?');
    ld2 = str2double(fscanf(osa));
    fprintf(osa,'sens:swe:poin?');
    nld = str2double(fscanf(osa));
end
y = mean(yi,2);
ysd = std(yi,0,2);
wavelength = transpose(linspace(ld1,ld2,nld));
figure(1); plot(wavelength/1e-9,y);
%% Clear
fclose(osa)
delete(osa);
clear osa;