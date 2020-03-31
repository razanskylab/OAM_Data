function Norm(M,maxVal,minVal)
  if nargin == 1 % normalize all maps seperately
    M.xy = normalize(M.xy);
  elseif nargin == 2  % normalize all maps to max val only (no substr.)
    M.xy = M.xy./maxVal;
  elseif nargin == 3  % normalize all maps to max val only (no substr.)
    M.xy = M.xy-minVal;
    M.xy = M.xy./maxVal;
  end
end
