function [recvStr, flag_recieve] = bpsk_rx_func(rxdata)
    global cyc;
    seq_sync = tx_gen_m_seq([1 0 0 0 0 0 1]);
    local_sync = tx_modulate(seq_sync, 'BPSK');
    rx_signal=rxdata;
    %% matched filtering
    fir = rcosdesign(1,128,4);
    rx_sig_filter = upfirdn(rx_signal,fir,1);
    %% normalization
    c1=max([abs(real(rx_sig_filter.')),abs(imag(rx_sig_filter.'))]);
    rx_sig_norm=rx_sig_filter ./c1;
    %% sampling synchronization
    [time_error,rx_sig_down]=rx_timing_recovery(rx_sig_norm.');
    % rx_sig_down=rx_sig_norm(1:4:end).';
    %% package search
    [rx_frame,cor_abs,th_max,index_s]=rx_package_search(rx_sig_down,local_sync,703);
    %% coarse freq synchronization
    coarse_sync_seq=rx_frame(1:8);
    [deltaf1,out_signal1] = rx_freq_sync(coarse_sync_seq,4,rx_frame);
    %% first fine freq synchronization
    fine_sync_seq_1=out_signal1(1:120);
    [deltaf2,out_signal2] = rx_freq_sync(fine_sync_seq_1,2,out_signal1);
    %% second fine freq synchronization
    fine_sync_seq_2=out_signal2(1:120);
    [deltaf3,out_signal3]=rx_freq_sync(fine_sync_seq_2,2,out_signal2);
    deltaf=deltaf1+deltaf2+deltaf3;
    %% initial phase estimate
    [out_signal4,ang]=rx_phase_sync(out_signal3,local_sync);
    %% phase track
    rx_no_syn_seq=out_signal4(127+1:end);
    [out_signal6,phase_curve]=rx_phase_track(rx_no_syn_seq);

    %% delete pilot
    out_signal7=rx_delete_pilot(out_signal6);
    %% time domain equalize
    out_signal8=rx_time_equalize(out_signal7);
    %% signal demod
    [soft_bits_out,evm] = rx_bpsk_demod(out_signal8);
    Si=[1 1 0 1 1 0 0];
    m=0;
    for i=1:length(soft_bits_out)
        [c,Si]=descramble(soft_bits_out(i),Si);
        m=m+1;
        y(m)=c;
    end
    soft_bits_out=y;
    %% crc32 check
    ret=crc32(soft_bits_out(1:length(soft_bits_out)-32)).';
    crc_bits_32=soft_bits_out(length(soft_bits_out)-31:length(soft_bits_out));
    crc_outputs=sum(xor(ret,crc_bits_32),2);

    if crc_outputs==0
        crc_32='YES';
        flag_recieve = 1;

    %     disp(char(b.'));
    %     disp(char(y));
    %     disp(char(soft_bits_out(1:end-32)));
    else
        crc_32='NO';
        flag_recieve = 0;
    end

    cyc=cyc+1;
    msg=soft_bits_out(1:end-32).';
    w = [128 64 32 16 8 4 2 1];
    Nbits = numel(msg);
    Ny = Nbits/8;
    y = zeros(1,Ny);
    for i = 0:Ny-1
        y(i+1) = w*msg(8*i+(1:8));
    end
    a=[y zeros(1,4)];
    b=reshape(a, 64, 1);

    recvStr = deblank(char(b.'));
    recvStr = strrep(recvStr,'$','');
end

