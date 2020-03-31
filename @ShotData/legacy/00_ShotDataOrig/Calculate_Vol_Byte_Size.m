% [out] = Calculate_Vol_Byte_Size(SDO,nX,nY,nZ) @ SDO
% calculates size of volumetric data set based on number of samples in X Y Z
% which are either taken from Pos subclass and nSamples or provided
% Johannes Rebling, (johannesrebling@gmail.com), 2018

function [byteSize,byteSizeStr] = Calculate_Vol_Byte_Size(SDO,nX,nY,nZ)
  if nargin == 1
    nX = SDO.Pos.nSteps(1);
    nY = SDO.Pos.nSteps(2);
    nZ = SDO.nSamples;
  elseif nargin ~= 4
    error('Need no or three inputs.');
  end
  dataType = class(SDO.vol); % get data type of vol data
  dummyVar = 0; % get dummy var
  dummyVar = cast(dummyVar,dataType); % and cast to same type as volume
  nBytesPerPoint = get_byte_size(dummyVar); % get nBytes for on entry in vol
  byteSize = nBytesPerPoint*nX*nY*nZ;

  % make nice looking SI string
  siStr = num_to_SI_string(byteSize);
  byteSizeStr = sprintf('%sB',siStr);
end
