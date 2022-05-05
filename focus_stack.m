%%
n = 1;
img_ca = {};
selected_tifs = [243, 263, 268, 275, 281, 304];
for i = 1:1:length(selected_tifs)
    img_num = selected_tifs(i);
    disp(img_num)
    img = imread(['better_water_fly_movie_tif_' num2str(img_num)],'tif');
    img_ca{n} = img;
    
    n = n + 1;
end
 
%%
% this is a color img
% copy values to grayscale
img_copy = img_ca;
for i = 1:length(img_copy)
    img_ca{i} = rgb2gray(img_ca{i});
end
 
% initialize filtered img
img_filtered = cell(size(img_ca));
% make a Laplacian of Gaussian (LoG) filter
log_filter = fspecial('log', [13 13], 2);
% structure element used to smooth focused parts
se = strel('ball', 31, 31);
% find edges for each img based on LoG filter
for i = 1:length(img_ca)    
    img_filtered{i} = imfilter(single(img_ca{i}), log_filter);
    img_filtered{i} = imdilate(img_filtered{i}, se, 'same');
end
 
%%
% initialize focus map
focus_map = ones(size(img_ca{1}), 'single');
% initialize LoG response
log_response = zeros(size(img_ca{1}), 'single');
 
% get all highest LoG responses
for i = 1:length(img_ca)
    index = img_filtered{i} > log_response;
    log_response(index) = img_filtered{i}(index);
    focus_map(index) = i;
end
 
% Gaussian smooth focus map
focus_map = imfilter(focus_map,fspecial('gaussian', [31 31], 3));
focus_map(focus_map < 1) = 1;
 
%%
% initialize output img
output_img = img_copy{1};
 
% get in-focus pixel from every image
for i = 1:length(img_ca)
    index = focus_map == i;
    index = repmat(index,[1 1 3]);
    output_img(index) = img_copy{i}(index);
end
 
figure(1);
imshow(output_img)
 
%%
% blend rest of focal z imgs
for i = 1:length(img_ca)-1
    index = focus_map > i & focus_map < i+1;
    index = repmat(index,[1 1 3]); % color
    fmap_c = repmat(focus_map, [1 1 3]); % color
    output_img(index) = ( fmap_c(index) - i) .* single(img_copy{i+1}(index)) +...
        (i + 1 - fmap_c(index)) .* single(img_copy{i}(index));
end
 
figure(2)
imshow(output_img)
imwrite(output_img, ‘ostracod_focus_stack.jpeg’)
