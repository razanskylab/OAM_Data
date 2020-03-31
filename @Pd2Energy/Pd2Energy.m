% Pd2Energy Class
% handles conversion from pd shots to energy or energy % equivalent a.u. for
% compensation of laser fluctuations during mesurement % % Johannes Rebling,
% (johannesrebling@gmail.com), 2018

% FIXME/TODO
% add laser power statistics -> get and plot to workspace
%
classdef Pd2Energy < handle

  properties
    % info on how data was recorded, all for reference, some for plotting %%%%%%
    mode(1,:) char {mustBeMember(mode,{'edge','oa','onda','dye'})} = 'edge';

    % sampling, important if different sampling rates are/will be used
    dt(1,1) double {mustBeNumeric} = 1./250e6; % assumed as default, change when needed
    prf(1,1) double {mustBeNumeric};
    power(1,1) double {mustBeNumeric};
    wavelength(1,1) double {mustBeNumeric};

    % settings for converting PD shots into energies %%%%%%%%%%%%%%%%%%%%%%%%%%%
    % remove noise floor from pd shots or not?
    doRemoveNoise(1,1) logical = true;
    % 1 = take sum, 0 = take max
    sumBased(1,1) logical = true;
    % take averate over these sample points to get noise floor
    noiseWindow(1,:) double {mustBeInteger} = 1:10;
    % sum over these sample points to get PD signal
    signalWindow(1,:) double {mustBeInteger} = 11:100;
    % max allowed fit order to be used, don't go higher than 3 or 4!!!
    maxFitOrder(1,1) double {mustBeInteger} = 2;

    % stored data
    pd(1,:) double {mustBeNumeric} = []; % [a.u.] not shots, just converted data
    pm(1,:) double {mustBeNumeric} = []; % [J]

    % mean/max/min pd vectors for plotting but so we don't have to store
    % raw data with the PD2E class
    pdMax(1,:) double {mustBeNumeric} = [];
    pdMin(1,:) double {mustBeNumeric} = [];
    pdMean(1,:) double {mustBeNumeric} = [];

    corValues(:,1) double {mustBeNumeric} = []; % results of calculating correlations

    doPlotSingleMeas = true;

    % polyVal double {mustBeNumeric}; % calculated based on correlation between PD and PM values
    Poly = struct( ...
      'coefficients',         [], ...
      'errorStruct',   [], ...
      'fitError',   [], ...
      'fitDelta',   [], ...
      'scaling',    []  );

    outTarget(1,1) double = 1; % 1 for workspace, 2 for standard error, or file id
  end

  % depended properties are calculated from other properties
  properties (Dependent = true)
  % calculated energies
  	shotEnergies; % [J], calculated from pd signals
    nPd;
    nPm;
    matchedPd; % pd a.u. energies scaled to match pm mean, usefull for plotting
    pmSort;
    pdSort;
    pmFit;
    pmFitUnsort;
  end

  % things we don't want to accidently change but that still might be interesting
  properties(SetAccess = private)
    FitResult = struct();
  end

  properties (Hidden=true)
  end

  % constant properties
  % https://de.mathworks.com/help/matlab/matlab_oop/properties-with-constant-values.html
  properties (Constant)
    FONT_SIZE = 10;
    LINE_WIDTH = 1.5;
    LEGEND_FONT_SIZE = 8;
  end

  % same as constant but now showing up as property
  properties (Constant,Hidden=true)
  end

  properties
  % defined in base class but this way we can have set/get in sublcasses, which
  % is % needed for FOAM processor
    silent(1,1) {mustBeNumericOrLogical} = false;
    verboseOutput(1,1) {mustBeNumericOrLogical} = true; % more detailed output to workspace...
    verbosePlotting(1,1) {mustBeNumericOrLogical} = false; % more figures...
    figureVisibility(1,:) char {mustBeMember(figureVisibility,{'on','off'})} = 'on';
  end


  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % constructor, desctructor, save obj
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  methods
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % constructor, called when class is created
    function PDE = Pd2Energy(varargin)
      % set default style, so that plotting is consistent...
      set(0,'DefaultAxesFontSize',PDE.FONT_SIZE);
      set(0,'DefaultTextFontSize',PDE.FONT_SIZE);
      set(0,'DefaultLineLinewidth',PDE.LINE_WIDTH);
      format compact;
      set(0,'defaultfigurecolor',[1 1 1]);

      % create deep copy of class if handed over as input
      className = class(PDE);
      if nargin && isa(varargin{1},className)
        [PDE] = deep_copy_handle_class(PDE,varargin{1});
      elseif nargin && contains('edge oa onda dye', lower(varargin{1}))
        PDE.mode = lower(varargin{1});
      end

    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Destructor: Mainly used to close the serial connection correctly
    function delete(~)
      % close connections etc
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % when saved, hand over only properties stored in saveObj
    function SaveObj = saveobj(PDE)
      % only save public properties of the class if you save it to mat file
      % without this saveobj function you will create an error when trying
      % to save this class
      SaveObj = PDE;
    end

    % Plot_Pd_Vs_Pm(PDE,plotOption);
  end


  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %% "Standard" methods, i.e. functions which can be called by the user and by
  % the class itself
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  methods
  end

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  methods (Access = private)

  end

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  methods
    % function acc = get.xyz(spi)
    % end
    % %===========================================================================
    % function set.xyz(spi, acc)
    % end
    function matchedPd = get.matchedPd(PDE)
      pmMean = mean(PDE.pm); % in uJ
      pdMean = mean(PDE.pd); %#ok<*PROP>
      energyRatio = pmMean/pdMean;
      matchedPd = PDE.pd.*energyRatio;
    end

    function nPd = get.nPd(PDE)
      nPd = numel(PDE.pd);
    end

    function nPm = get.nPm(PDE)
      nPm = numel(PDE.pm);
    end

    function pd = get.pd(PDE)
      pd = PDE.pd(:);
    end

    function pm = get.pm(PDE)
      pm = PDE.pm(:);
    end

    function pmSort = get.pmSort(PDE)
      pmSort = sort(PDE.pm);
    end

    function pdSort = get.pdSort(PDE)
      % sort PD values based on pm values
      [~,sortIdx] = sort(PDE.pm);
      pdSort = PDE.pd(sortIdx);
    end

    function pmFit = get.pmFit(PDE)
      if isempty(PDE.Poly.coefficients)
        pmFit = [];
      else
        [pmFit,fitDelta] = polyval(PDE.Poly.coefficients,...
                                   PDE.pdSort,...
                                   PDE.Poly.errorStruct,...
                                   PDE.Poly.scaling);
        PDE.Poly.fitDelta = fitDelta;
      end
    end

    function pmFitUnsort = get.pmFitUnsort(PDE)
      if isempty(PDE.Poly.coefficients)
        pmFitUnsort = [];
      else
        [pmFitUnsort,fitDelta] = polyval(PDE.Poly.coefficients,...
                                   PDE.pd,...
                                   PDE.Poly.errorStruct,...
                                   PDE.Poly.scaling);
        PDE.Poly.fitDelta = fitDelta;
      end
    end

    function shotEnergies = get.shotEnergies(PDE)
      if isempty(PDE.Poly.coefficients) && ~isempty(PDE.pd)
        % we have pd values (a.u.) and want to use the to correct laser
        % fluctuations but we don't have a pd cal file (shame on you)
        % so we just create fake shot energies with mean = 1
        shotEnergies = PDE.pd;
        shotEnergies = shotEnergies./mean(shotEnergies);
      elseif ~isempty(PDE.Poly.coefficients) && ~isempty(PDE.pd)
        % we have poly fit values, so we can calculate real per pulse energies
        shotEnergies = PDE.pmFitUnsort;
      else
        shotEnergies = [];
      end
    end
  end
end
