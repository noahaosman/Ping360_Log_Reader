clc

%INPUT---------------------------------------------------

datatypes = ["angle" "sample_period" "data" "timestamp" "number_of_samples"];
input_data = "20220824-021252749";

%--------------------------------------------------------


directory = input_data;

if ~isfolder(directory)
    decoded_file = join([input_data,".decoded"],"");
    if ~isfile(decoded_file)
        disp("Decoding log file ...")
        system(join([ "python3 decode_sensor_binary_log.py ", join([input_data,".bin"],"") ],""));
    end

    disp("formatting for import to Matlab ...")
    %system("chmod +x clean_up_ping_data.sh") % make bash script an executable (if havent already)
    system(join(["./clean_up_ping_data.sh",decoded_file, join(datatypes," ")]," "))
end

vars = strcat("ping.",datatypes);
for i=1:length(datatypes)

    disp(join(["importing ",datatypes(i),".dat ..."],""))

    eval(join([vars(i)," = sparse(load('",join([directory,"/",datatypes(i),".dat"],""),"'));"],""))

end

% convert angle from gradians to degrees, and set 0 deg at arrow on bottom
% of ping360
ping.angle = 0.9.*ping.angle - 200;

disp("Done!")

%% plot individual pings

set(groot,'defaultTextInterpreter','latex')
set(groot,'defaultAxesTickLabelInterpreter','latex');
figure(1)
for data_ind = 28270:length(ping.angle)

    x = get_distance(ping.sample_period(data_ind),ping.number_of_samples(data_ind));
    plot(x,ping.data(data_ind,:),'-k')
    title( {join(['angle = $',num2str(ping.angle(data_ind)),' ^\circ$']),join(['timestamp: $', ...
        get_timestamp_str(full(ping.timestamp(data_ind,:))),'$'])})
    ylim([0,255])
    xlabel('Distance $(m)$')
    ylabel('Intensity')
    set(gca,'fontsize', 14) 
    pause

end

%% plot one angle sweep (not carefully coded, just a proof of concept)

ang1_ind = 5562;
ang2_ind = 5826;

h=polar([0 2*pi],[0 2]);delete(h);     %Create a polar axes and delete the line specified by POLAR
hold on;      
A = ping.angle(ang1_ind:ang2_ind);
R = get_distance(ping.sample_period(ang1_ind),ping.number_of_samples(ang1_ind));
Z = ping.data(ang1_ind:ang2_ind,:)';
[theta, rho] = meshgrid(A*pi/180, R);
[X, Y] = pol2cart(theta, rho);
contour(X, Y,Z,4)                              %Create contour plots in polar coordinates onto polar chart 
set(gca,'visible','off');          


%% functions
function x = get_distance(sample_period, number_of_samples)
    
    % calculate distance in meters for a given sample period and number of
    % data pts.
    c = 1500;
    sample_inc = 25*10^-9;
    x = (0.5*c*sample_inc)*sample_period.*(0:number_of_samples-1)';

end

function time_str = get_timestamp_str(timestamp)

    time_str = join([timestamp(1),timestamp(2),":",timestamp(3),timestamp(4),":",timestamp(5),timestamp(6),".",timestamp(7),timestamp(8),timestamp(9)],"");

end

