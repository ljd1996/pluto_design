function [ input_content, output_content, s ] = pluto_config( pluto_init, txdata )

% System Object Configuration
s = iio_sys_obj_matlab; % MATLAB libiio Constructor
s.ip_address = pluto_init.ip;
s.dev_name = 'ad9361';
s.in_ch_no = 2;
s.out_ch_no = 2;
s.in_ch_size = length(txdata);
s.out_ch_size = length(txdata)*6;

s = s.setupImpl();

input_content = cell(1, s.in_ch_no + length(s.iio_dev_cfg.cfg_ch));
output_content = cell(1, s.out_ch_no + length(s.iio_dev_cfg.mon_ch));

input_content{s.getInChannel('RX_LO_FREQ')} = pluto_init.rx_freq;
input_content{s.getInChannel('RX_SAMPLING_FREQ')} = pluto_init.rx_samp;
input_content{s.getInChannel('RX_RF_BANDWIDTH')} = pluto_init.rx_bw;
input_content{s.getInChannel('RX1_GAIN_MODE')} = pluto_init.rx_gain_mode;
input_content{s.getInChannel('RX1_GAIN')} = 10;

input_content{s.getInChannel('TX_LO_FREQ')} = pluto_init.tx_freq;
input_content{s.getInChannel('TX_SAMPLING_FREQ')} = pluto_init.tx_samp;
input_content{s.getInChannel('TX_RF_BANDWIDTH')} = pluto_init.tx_bw;

txdata = int16(txdata.*2^14);
input_content{1} = real(txdata);
input_content{2} = imag(txdata);

end

