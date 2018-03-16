function txdata = bpsk_tx_func(msgStr)
%% train sequence
seq_sync=tx_gen_m_seq([1 0 0 0 0 0 1]);
sync_symbols=tx_modulate(seq_sync, 'BPSK');

while (length(msgStr) < 60)
    msgStr = [msgStr, char('$')];
end

%% string to bits
mst_bits=str_to_bits(msgStr);
%% crc32
ret=crc32(mst_bits);
inf_bits=[mst_bits ret.'];
%% scramble
scramble_int=[1,1,0,1,1,0,0];
sym_bits=scramble(scramble_int, inf_bits);
%% modulate
mod_symbols=tx_modulate(sym_bits, 'BPSK');
%% insert pilot
data_symbols=insert_pilot(mod_symbols);
trans_symbols=[sync_symbols data_symbols];
%% srrc
fir=rcosdesign(1,128,4);
tx_frame=upfirdn(trans_symbols,fir,4);
tx_frame=[tx_frame, zeros(1,2e3)];
txdata = tx_frame.';

end

