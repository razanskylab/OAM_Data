% Interpolate --------------------------------------------------------------
function Interpolate(M,interpFactor)
  % interpolate xy map and update x and y vectors accordingly
  if nargin == 2
    M.interpFactor = interpFactor;
  end
  tic;
  % only output text if verbose output is on...
  M.VPrintF('[Map] Interpolating (k=%i)...',M.interpFactor);

  % get interpolated x and y vectors
  xI = M.x(1):(M.dX/M.interpFactor):M.x(end);
  yI = M.y(1):(M.dY/M.interpFactor):M.y(end);
  % turn 400 x 400 px image into 800 x 800 px image and not 799 x 799
  xI = linspace(M.x(1),M.x(end),length(xI)+1);
  yI = linspace(M.y(1),M.y(end),length(yI)+1);
  % interpolate xy maps based on new x-y vectors
  [X,Y] = meshgrid(M.x,M.y);
  [XI,YI] = meshgrid(xI,yI);
  M.xy = interp2(X,Y,M.xy,XI,YI,M.interpMethod);
  % also update depth info if present
  if ~isempty(M.depthInfo)
    M.depthInfo = interp2(X,Y,M.depthInfo,XI,YI,M.interpMethod);
  end
  M.x = xI;
  M.y = yI;
  % only output text if verbose output is on...
  M.Done();
end
