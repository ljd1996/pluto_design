clearvars -except times;close all;warning off;

pluto_init.ip = '192.168.2.1';
pluto_init.rx_freq = 2000e6;
pluto_init.rx_samp = 40e6;
pluto_init.rx_bw = 20e6;
pluto_init.rx_gain_mode = 'manual';
pluto_init.tx_freq = 2000e6;
pluto_init.tx_samp = 40e6;
pluto_init.tx_bw = 20e6;

addpath ieee802_11a\transmitter_matlab
in_byte=repmat([1:100],1,10);
rate=54;
upsample=2;
tx_11a=ieee802_11a_tx_func(in_byte,rate,upsample);
txdata=repmat([zeros(size(tx_11a));tx_11a],8,1);
[input_content, output_content, s] = pluto_config(pluto_init, txdata);

while(i<8)
    output_content = stepImpl(s, input_content);
    i=i+1;
end

I = output_content{1};
Q = output_content{2};
Rx = I+1i*Q;

upsample=2;
addpath ieee802_11a\receiver_matlab
[data_byte_recv,sim_options] = ieee802_11a_rx_func(Rx(:,1),upsample);