%enb=struct('NCellID',424,'NDLRB',100,'NSubframe',9,'CFI',2,'CyclicPrefix','Normal','CellRefP',2,'Ng','One','PHICHDuration','Normal','DuplexMode','FDD');

RNTI=65535;

addpath('../../build/srslte/lib/phch/test')

cec.PilotAverage = 'UserDefined';     % Type of pilot averaging
cec.FreqWindow = 9;                   % Frequency window size    
cec.TimeWindow = 9;                   % Time window size    
cec.InterpType = 'linear';             % 2D interpolation type
cec.InterpWindow = 'Causal';        % Interpolation window type
cec.InterpWinSize = 1;                % Interpolation window size  

%subframe_rx=lteOFDMDemodulate(enb,inputSignal);
subframe_rx=reshape(input,[],14);
[hest,nest] = lteDLChannelEstimate(enb, cec, subframe_rx);    
    
% Search PDCCH
pdcchIndices = ltePDCCHIndices(enb); 
[pdcchRx, pdcchHest] = lteExtractResources(pdcchIndices, subframe_rx, hest);
[dciBits, pdcchSymbols] = ltePDCCHDecode(enb, pdcchRx, pdcchHest, nest);
pdcch = struct('RNTI', RNTI);  
dci = ltePDCCHSearch(enb, pdcch, dciBits); % Search PDCCH for DCI                

if ~isempty(dci)
        
    dci = dci{1};
    disp(dci);
    
    % Get the PDSCH configuration from the DCI
    [pdsch, trblklen] = hPDSCHConfiguration(enb, dci, pdcch.RNTI);
    pdsch.NTurboDecIts = 10;
    %pdsch.Modulation =  {'QPSK'};
    %trblklen=75376;
    fprintf('PDSCH settings after DCI decoding:\n');
    disp(pdsch);

    fprintf('Decoding PDSCH...\n\n');        
    % Get PDSCH indices
    [pdschIndices,pdschIndicesInfo] = ltePDSCHIndices(enb, pdsch, pdsch.PRBSet);
    [pdschRx, pdschHest] = lteExtractResources(pdschIndices, subframe_rx, hest);
    % Decode PDSCH 
    [dlschBits,pdschSymbols] = ltePDSCHDecode(enb, pdsch, pdschRx, pdschHest, nest);
    [sib1, crc] = lteDLSCHDecode(enb, pdsch, trblklen, dlschBits);

    [dec2, data, pdschRx2, pdschSymbols2, e_bits] = srslte_pdsch(enb, pdsch, ... 
                                                        trblklen, ...
                                                        subframe_rx, hest, nest);

    
    scatter(real(pdschSymbols{1}),imag(pdschSymbols{1}))

    if crc == 0
        fprintf('PDSCH OK.\n\n');
    else
        fprintf('PDSCH ERROR.\n\n');
    end
        
    else
        % indicate that DCI decoding failed 
        fprintf('DCI decoding failed.\n\n');
end

%indices=indices+1;
%plot(t,indices(t),t,pdschIndices(t))
    