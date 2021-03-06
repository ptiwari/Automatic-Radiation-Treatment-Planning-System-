%patID = 104;

format long;
if ~exist('loadDirectory'), loadDirectory = '/research-projects/tantra/tiwarip/imrt/'; end
loadDirectory = '~/imrt/';
disp('Loading data...');
eval(['load ' loadDirectory 'case',int2str(patID), '.mat']); %_9b_s1_th01
global planC; % (input parameter now)
choppedIM = size(planC{planC{end}.IM},2);
initFileName = sprintf('init_case_%d',patID);
initwdExt = strcat(initFileName,'.m');

if(exist(initwdExt,'file')==0)
    getParametersHN(planC,patID);
end

eval(initFileName);
choppedIM = size(planC{planC{end}.IM},2);
indexS = planC{end};
influenceM = getGlobalInfluenceM2(planC{indexS.IM}(choppedIM).IMDosimetry, unique([targets step2OARs step3OARs]));
b =[];
nm=[];
getAllVoxel

%Maximum organ id. This is used in the C code to allocate the size of
%voxels.
num=0;
for tar = 1:length(targets)
    t1 = influenceM(allVoxelC{targets(tar)},:);
    %     a = logical(t1);
    %     a = sum(a);
    %     col = find(a==0);
    %     influenceM(:,col)=[];
    %     t1 = influenceM(allVoxelC{targets(tar)},:);
    num = num+size(find(t1),1);
    
end
morganId = max(unique([targets step2OARs step3OARs]));
numPBs = size(influenceM,2);
%[r,c,val]=find(influenceM);
[c,r,val]=find(influenceM');
numRow = size(r,1);
col = size(influenceM,2);
row = size(influenceM,1);

r = r-1;
c=c-1;
numVar=0;

numStepI=0;
for oar = 1:length(step1OARs)
    t1 = influenceM(allVoxelC{step1OARs(oar)},:);
    numStepI = numStepI+size(find(t1),1);
    
end
numStepII = 0;
for oar = 1:length(step2OARs)
    t1 = influenceM(allVoxelC{step2OARs(oar)},:);
    numStepII = numStepII+size(find(t1),1);
    
end
numPBs = size(influenceM,2);
numTargets = length(targets);
hessianM = sparse(numPBs,numPBs);
for tar = 1:length(targets)
    hessianM = hessianM + ( 1/numAllVoxels(targets(tar)) ) * ...
        influenceM(allVoxelC{targets(tar)},:)' * influenceM(allVoxelC{targets(tar)},:);
end
hessianM = [hessianM                  sparse(numPBs,numTargets)         ; ...
    sparse(numTargets,numPBs) speye(numTargets) ];

hessVal = cell(numTargets,1);
hessRow =  cell(numTargets,1);
hessCol =  cell(numTargets,1);
rowSize = zeros(numTargets);
for tar = 1:numTargets
    h = sparse(numPBs,numPBs);
    h = ( 1/numAllVoxels(targets(tar)) ) * ...
        influenceM(allVoxelC{targets(tar)},:)' * influenceM(allVoxelC{targets(tar)},:);
    h = 2*h;
    [hr,hc,hv] = find(tril(h));
    hr = hr-1;
    hc = hc-1;
    hessRow{tar} = hr;
    hessCol{tar} = hc;
    hessVal{tar} = hv;
    rowSize(tar) = size(hr,1);
end

clear influenceM;
hessianM = 2 * hessianM;
[lr,lc,lv] = find(tril(hessianM));
lr=lr-1;
lc=lc-1;
nlr = size(lr,1);
s = logical(find(lr<=numPBs));
total=sum(s);
clear hessianM;
for i=1:size(allVoxelC,2)
    v = allVoxelC{i};
    v = v-1;
    allVoxelC{i}=v;
end
