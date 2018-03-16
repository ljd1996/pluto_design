clearvars -except times;close all;warning off;
set(0,'defaultfigurecolor','w');
addpath .\library
addpath .\library\matlab

ip = '192.168.2.1';
addpath BPSK\transmitter
addpath BPSK\receiver

%% System Object Configuration
s = iio_sys_obj_matlab; % MATLAB libiio Constructor
s.ip_address = ip;
s.dev_name = 'ad9361';
s.in_ch_no = 2;
s.out_ch_no = 2;
s.in_ch_size = 42568;
s.out_ch_size = 42568 * 8;

s = s.setupImpl();

inputPluto = cell(1, s.in_ch_no + length(s.iio_dev_cfg.cfg_ch));
output = cell(1, s.out_ch_no + length(s.iio_dev_cfg.mon_ch));

% Set the attributes of AD9361
inputPluto{s.getInChannel('RX_LO_FREQ')} = 2e9;
inputPluto{s.getInChannel('RX_SAMPLING_FREQ')} = 40e6;
inputPluto{s.getInChannel('RX_RF_BANDWIDTH')} = 20e6;
inputPluto{s.getInChannel('RX1_GAIN_MODE')} = 'manual';%% slow_attack manual
inputPluto{s.getInChannel('RX1_GAIN')} = 10;
% inputPluto{s.getInChannel('RX2_GAIN_MODE')} = 'slow_attack';
% inputPluto{s.getInChannel('RX2_GAIN')} = 0;
inputPluto{s.getInChannel('TX_LO_FREQ')} = 2e9;
inputPluto{s.getInChannel('TX_SAMPLING_FREQ')} = 40e6;
inputPluto{s.getInChannel('TX_RF_BANDWIDTH')} = 20e6;

%% Transmit and Receive using MATLAB libiio

seqNum = 0;

flagSuccess = 0;

isFirst = 1;

while true
    output = recieve_data(s);
    I = output{1};
    Q = output{2};
    Rx = I + 1i * Q;

    [rStr, isRecieved] = bpsk_rx_func(Rx(end / 2 : end));
    if (~isRecieved)
        continue;
    else
        if (rStr(1) == '0')
            if isFirst == 1
                isFirst = 0;
                fprintf('receive: %s\n', rStr(5 : end));
                seqNum = str2num(rStr(2 : 4));
            elseif seqNum ~= str2num(rStr(2 : 4));
                fprintf('receive: %s\n', rStr(5 : end));
                seqNum = str2num(rStr(2 : 4));
            end
            sendData = ['1', rStr(2 : 4)];
            txdata = bpsk_tx_func(sendData);
            txdata = round(txdata .* 2^14);
            txdata = repmat(txdata, 8, 1);
            inputPluto{1} = real(txdata);
            inputPluto{2} = imag(txdata);
            send_data(s, inputPluto);

            continue;
        end
    end
end

fprintf('Transmission and reception finished\n');
fprintf('recievedData: %s\n', recievedStr);

% Read the RSSI attributes of both channels
rssi1 = output{s.getOutChannel('RX1_RSSI')};
% rssi2 = output{s.getOutChannel('RX2_RSSI')};

s.releaseImpl();
