% [out] = Find_Shot_Jitter(SDO,In) @ SDO
% Johannes Rebling, (johannesrebling@gmail.com), 2018
% find SDO.jitter

function Find_Shot_Jitter(SDO)
  SDO.jitter = [];
  if isempty(SDO.raw) || ~numel(SDO.raw)
    short_warn('Can''t detect shift without data!');
    return;
  end

  % NOTE jitter settings, might be worth putting into extra file / struct at
  % some point
  cropPdSignals = true;
  cropPdSafetyMargin = 5;
  interpFactor = 4;
  detectionMethod = 0;


  if ~SDO.verboseOutput
    SDO.PrintF('Detecing shot z-jitter...\n');
  end
  SDO.VPrintF('   Detecing shot z-jitter!\n');
  % FIXME this is only to correct jitter based on known, per shot shift values
  % finding jitter is done in seperate function


  pdShots = single(SDO.raw);
  pdShots = pdShots./(max(pdShots));
    % use  implicit expansion of arrays with compatible sizes here
    % see bsxfun

  meanShot = mean(pdShots,2);
  [~,maxOffsetIdx] = max(meanShot);


  % crop pd signals closer to actual peak prior to processing for speed up------
  tic;
  if cropPdSignals
    SDO.VPrintF('      Cropping shots to increase detection speed...')
    maxShot = max(pdShots,[],2); % get max rather then mean to be on save side...
    % crop out part that contains data to speed up processing
    startRange = find(maxShot>0.02,1,'first')-cropPdSafetyMargin;
    startRange = max([1 startRange]); % make sure startRange >= 1
    endRange = find(maxShot>0.05,1,'last')+cropPdSafetyMargin;
    endRange = min([size(pdShots,1) endRange]); % make sure startRange <= nPD samples

    pdShots = pdShots(startRange:endRange,:);
    SDO.Done();
  end
  nSamples = size(pdShots,1);
  nShots = size(pdShots,2);


  % interpolate for more accurate shifts -----------------------------------------
  tic;
  if interpFactor > 1
    SDO.VPrintF('      Interpolating shots to find sub-sample shift...')
    regularInterval = 1:nSamples;
    interpInterval = linspace(1,nSamples,nSamples*interpFactor);
    pdShots = interp1(regularInterval,pdShots,interpInterval,'linear');
    SDO.Done();
  end

  meanShot = mean(pdShots,2);

  % find pd signal shift depending on what you like...
  tic;
  switch detectionMethod
  case 0 % fully vectorized version without xcorr ------------------------------
    SDO.VPrintF('      Detecting shift using 0->1->0 transition...')
    % detects point of transition from 0->1 and 1->0 at value 0.5
    % shift is detected as mean of both values

    % find individual max positions
    [~,shotMaxIdx] = max(pdShots,[],1);

    % rougly shift pdShots based on PD max to separate rising and falling edges
    shiftVector = shotMaxIdx - round(mean(shotMaxIdx(:))); % shifting values

    % [shiftedShots] = shift_matrix_rows(pdShots,shiftVector); %
    [shiftedShots] = shift_matrix_cols(pdShots,shiftVector);

    % find idx of transition in rising and falling edges seperately
    meanShotSub = abs(meanShot - 0.5); % gives two minima at transition points
    meanShot = mean(shiftedShots,2);
    [~,divideIdx] = max(meanShot); % split shot matrix at this point to seperate rising and fallin edge
    [~,leftTransition] = min(meanShotSub(1:divideIdx));
    [~,rightTransition] = min(meanShotSub(divideIdx:end));

    myShotSub = abs(shiftedShots-0.5);
    myShotSubLeft = myShotSub(1:divideIdx,:);
    myShotSubRight = myShotSub(divideIdx:end,:);
    [~,leftMin] = min(myShotSubLeft,[],1); % find first 0.5 crossing
    [~,rightMin] = min(myShotSubRight,[],1); % search for second 0.5 crossing after peak

    % detect shift as average difference of transtion idx in mean and seperate pdShots
    sigShifts = (leftMin-leftTransition + rightMin-rightTransition)./2;
    SDO.jitter = round(sigShifts)+shiftVector; % combines rough and fine shifting

  % case 1 % ---------------------------------------------------------------------
  %   SDO.VPrintF('Detecting shift using vectorized x-corr...')
  %   pdShots = pdShots';
  %   meanShot = meanShot(:);
  %   crossCorr = fft_xcorr(meanShot,pdShots);
  %   [~, sigShifts] = max(abs(crossCorr));
  %   SDO.jitter = sigShifts - (nSamples + maxOffsetIdx)*interpFactor;
  %
  % case 2 % ---------------------------------------------------------------------
  %   SDO.VPrintF('Detecting shift using max. value...')
  %   % rougly shift pdShots to separate rising and falling edges
  %   [~,shotMaxIdx] = max(pdShots,[],2);
  %   SDO.jitter = shotMaxIdx-round(mean(shotMaxIdx(:))); % shifting values
  %
  % case 3  % ---------------------------------------------------------------------
  %   SDO.VPrintF('Detecting shift using par-for x-corr...')
  %   % prepare parfor loop if needed
  %   if Conf.parallelProcessing
  %     % run as many for loops in parallel as workers (cores)
  %     parForArgument = inf; % don't run in parallel
  %   else
  %     parForArgument = 0; % don't run in parallel
  %   end
  %
  %   pdShots = pdShots'; % need to be trensposed for crosscor, fast to do it here once
  %   sigShifts = zeros(nShots,1);
  %   parfor (iShot = 1:nShots,parForArgument)
  %     crossCorr = fft_xcorr(pdShots(:,iShot),meanShot);
  %     [~,sigShifts(iShot)] = max(abs(crossCorr(:)));
  %   end
  %   SDO.jitter = sigShifts - (nSamples + maxOffsetIdx)*interpFactor;
  otherwise
    error('Unknown jitter removal methods! Needs to be 1!');
  end
  SDO.Done();

  % % SDO.jitter correction
  % Conf.NoJitter.use = 1; % use SDO.jitter removal?
  % Conf.NoJitter.cropPdSignals = true; % crop pd signals prior to processing for speed up
  % Conf.NoJitter.interpFactor = 4; % 4 is better for transition method, 2 is ok for other
  % Conf.NoJitter.detectionMethod = 0;
  % % 0 - vec. transition, 1 - vect. xCorr, 2 - vect. max, 3 - parfor xCorr

  % find SDO.jitter from pd signals
  % [usShots] = remove_shot_SDO.jitter(usShots,ExpData,Conf);

  if SDO.verbosePlotting()
    figure()
    [shiftedMatrix] = shift_matrix_cols(pdShots,SDO.jitter);
    subplot(2,3,1);
      imagesc(pdShots(:,1:100))
      title('orig');
    subplot(2,3,2);
      imagesc(shiftedShots(:,1:100))
      title('rough shift');

    subplot(2,3,3);
      imagesc(shiftedMatrix(:,1:100));
      title('fine shifted');

     subplot(2,3,4)
       plot(meanShot)
       hold on
       plot(pdShots(:,1))
       plot([maxOffsetIdx, maxOffsetIdx],[0,1],'k')
       title('meanShot')

     subplot(2,3,5)
       pretty_hist(sigShifts)
       title('sigShifts')

     subplot(2,3,6)
       pretty_hist(SDO.jitter)
       title('jitter')
  end

end
