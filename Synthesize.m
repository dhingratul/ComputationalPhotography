%% Synthesize texture
% Implemented Efros and Leung’s approach, to synthesize a 200x200 pixel
% image for given image with varying WindowSize parameter.
% Input: SampleTexture, Image
% Output: Synthesize image
function [Image]= Synthesize(SampleImage,Image,WindowSize,DrawTexture)
SampleImage = im2col(Image,[(2 * WindowSize + 1) (2 * WindowSize + 1)]);
[r,c] = find(SampleImage == 0);
SampleImage(:,c) = [];
%% GetUnfilledNeighbors
mask = logical(Image);
se = strel('square',3);
border = imdilate(mask,se) - mask;
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
while(numel(Zero)>70)
    NonZero=any(Image);
    Zero=find(NonZero==0);
    for i = 1:size(PixelList,1)
        %% GetNeighborhood Window
        Window(:,:,i) = Image(PixelList(i,1) - (WindowSize): PixelList(i,1) + (WindowSize), PixelList(i,2) - (WindowSize): PixelList(i,2) + (WindowSize));
        Template(:,:) = Window(:,:,i);
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
        size(BestMatches);
        %% RandomPick
        BestMatch = BestMatches(1 + (floor(rand(1)) .* length(BestMatches)));
        Image(PixelList(i,1),PixelList(i,2)) = BestMatch;
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

Image( ~any(Image,2), : ) = [];
Image( :, ~any(Image,1) ) = [];
Image=imresize(Image,[200,200]);
imshow(uint8(Image)); %show final image
end