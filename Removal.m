%% Object Removal
% Implemented Criminisi’s approach, to for object removal
% Input: SampleImage, Image, WindowSize, DrawTexture(0 or 1)
% Output: Object removed image
% Note: Run from RunObjectRemoval.m
function [Image]= Removal(SampleImage,Image,WindowSize,DrawTexture)
[r_new,c_new]=size(Image);
if(c_new>600)
    pad=100;
else
    pad=40;
end
Image=padarray(Image,[pad,pad]);

SampleImage = im2col(Image,[(2 * WindowSize + 1) (2 * WindowSize + 1)]);
[r,c] = find(SampleImage == 0);
SampleImage(:,c) = [];
%% GetUnfilledNeighbors
mask = logical(Image);
se = strel('square',3);
border = imdilate(mask,se) - mask; %Border Pixels
[r,c] = find(border);
PixelList = [r c];
%%
ErrThreshold = 0.1;
MaxErrThreshold = 0.3;
Sigma = (WindowSize*2 + 1)/6.4;
Window = zeros(WindowSize*2 + 1,WindowSize*2 + 1,size(PixelList,1));
Template = zeros(WindowSize*2 + 1,WindowSize*2 + 1);
%% Grow Image
progress = 0;
NonZero=any(Image);
Zero=find(NonZero==0);
while(numel(Zero)>20)
    NonZero=any(Image);
    Zero=find(NonZero==0);
    for i = 1:size(PixelList,1)
        %% GetNeighborhood Window
        Window(:,:,i) = Image(PixelList(i,1) - (WindowSize): PixelList(i,1) + (WindowSize), PixelList(i,2) - (WindowSize): PixelList(i,2) + (WindowSize));
        Template(:,:) = Window(:,:,i); %Template for pixel around pixel in PixelList
        %% FindMatches
        ValidMask = logical(Template);
        GaussMask = fspecial('gaussian',WindowSize*2 + 1,Sigma);
        dotproduct = GaussMask .* ValidMask;
        TotalWeight = sum(sum(dotproduct));
        %% BestMatches
        dotproduct = dotproduct(:) * ones(1,size(SampleImage,2));
        vector = Template(:);
        tempmtx = vector * ones(1,size(SampleImage,2));
        dist = (SampleImage - tempmtx).^2;
        SSD = dist.*dotproduct;
        SSD = sum(SSD)./TotalWeight;
        idx = find(SSD <= min(SSD) .* (1 + ErrThreshold));
        mid = ((WindowSize * 2 + 1).^2+1)/2;
        BestMatches = SampleImage(mid,idx);
        %% RandomPick
        BestMatch = BestMatches(1 + (floor(rand(1)) .* length(BestMatches)));
        Image(PixelList(i,1),PixelList(i,2)) = BestMatch; %replace pixel coordinates' values with BestMatch pixel value
        progress = progress + 1;
        %% Display image while growing texture
        if(DrawTexture==1)
            imagesc(Image);
            axis image; colormap gray;
            drawnow;
        end
    end
    mask = logical(Image);
    border = imdilate(mask,se) - mask;
    [r,c] = find(border);
    PixelList = [r c];
end
imshow(uint8(Image)); %show final image
end