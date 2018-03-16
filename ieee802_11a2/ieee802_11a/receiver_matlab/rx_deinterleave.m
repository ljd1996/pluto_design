

function out_bits = rx_deinterleave(in_bits, Modulation)

%���Ncbps
interleaver_depth =48* get_bits_per_symbol(Modulation); 
%OFDM������
num_symbols = length(in_bits)/interleaver_depth;

%�ѵ���һ��OFDM���ŵ�˳��������
single_deintlvr_patt = rx_gen_deintlvr_patt(interleaver_depth);
deintlvr_patt = interleaver_depth*ones(interleaver_depth, num_symbols);
deintlvr_patt = deintlvr_patt*diag(0:num_symbols-1);
deintlvr_patt = deintlvr_patt+repmat(single_deintlvr_patt', 1, num_symbols);
deintlvr_patt = deintlvr_patt(:);

out_bits(deintlvr_patt) = in_bits;

