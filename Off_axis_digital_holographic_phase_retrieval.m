%% Metasurface Angular Alignment Phase Extraction Pipeline
% Description: Extracts and analyzes phase information from experimental images 
%              for spatial/angular alignment using Fourier-domain filtering.
% Author: Your Name
% Date: 2026

close all; clear; clc;

%% ==================== 1. 参数与路径配置 ====================
% 数据与参考图路径
dataFolderPath = 'F:\Doctor\Angular Alignment\实验图片\20250909\-11'; 
refImagePath   = 'F:\Doctor\Angular Alignment\实验图片\20250908\ref 11.tif';

% 频谱滤波器参数 (根据载波频率峰值调整)
freq_peak = [709, 320];  % [Col, Row] / [u0, v0] 核心峰值位置
a = 70;                  % 椭圆滤波器长轴
b = 70;                  % 椭圆滤波器短轴
sigma = 15;              % 高斯衰减边界宽度

% 目标感兴趣区域 (ROI) 裁剪边界 [Row_start:Row_end, Col_start:Col_end]
roi_ms1 = {395:570, 786:960};
roi_ms2 = {575:750, 695:870};
target_size = [1000, 1000]; % 插值后的目标分辨率

%% ==================== 2. 图像文件读取与自动排序 ====================
fileList = dir(fullfile(dataFolderPath, '*.tif'));
numFiles = numel(fileList);
fileNames = {fileList.name};
fileNumbers = zeros(1, numFiles);

% 使用正则表达式提取文件名中的角度/序列数字
for i = 1:numFiles
    numStr = regexp(fileNames{i}, '[-+]?[0-9]*\.?[0-9]+(?:e[-+]?[0-9]+)?', 'match', 'once');
    if ~isempty(numStr)
        fileNumbers(i) = str2double(numStr);
    else
        fileNumbers(i) = NaN;
    end
end

% 按数字升序对文件进行排序
[~, sortIdx] = sort(fileNumbers, 'ascend');
sortedFiles = fileNames(sortIdx);

% 预分配内存并加载图像序列
firstImg = imread(fullfile(dataFolderPath, sortedFiles{1}));
[height, width] = size(firstImg);
imgStack = zeros(height, width, numFiles, 'like', firstImg);

for i = 1:numFiles
    imgStack(:, :, i) = imread(fullfile(dataFolderPath, sortedFiles{i}));
end
fprintf('成功加载并排序 %d 张实验图片。\n', numFiles);

%% ==================== 3. 构建频域高斯滤波器 ====================
pic_ref = imread(refImagePath);
[m, n] = size(pic_ref);
pic_ref_fft = fftshift(fft2(pic_ref));

% 构建频域网格
[u, v] = meshgrid((0:n-1) - floor(n/2), (0:m-1) - floor(m/2));
u0 = freq_peak(1) - floor(n/2);
v0 = freq_peak(2) - floor(m/2);

% 计算椭圆归一化距离
r2 = ((u - u0)/a).^2 + ((v - v0)/b).^2;

% 构建带有平滑过渡带的滤波器
filter_mask = ones(m, n);
transition = exp(-((r2 - 1).^2) / (2 * (sigma/a)^2));
filter_mask(r2 > 1) = transition(r2 > 1);
filter_mask(r2 > 2) = 0;

% 对参考图进行滤波
pic_ref_filtered = ifft2(ifftshift(pic_ref_fft .* filter_mask));

%% ==================== 4. 核心解相与相位提取 ====================
phase_bank = zeros(size(imgStack));

for q = 1:numFiles
    pic_fft = fftshift(fft2(imgStack(:, :, q)));
    pic_filtered = ifft2(ifftshift(pic_fft .* filter_mask));
    
    % 通过复数除法（共轭相减）提取相对复振幅与相位
    E = pic_filtered ./ pic_ref_filtered;
    phase_bank(:, :, q) = angle(E);
end 

%% ==================== 5. ROI 提取与相位安全插值 ====================
% 以第 4 张图片为例进行后处理展示
sample_phase = phase_bank(:, :, 4);

% Metasurface 1 ROI 提取与重采样
phi_ms1_raw = sample_phase(roi_ms1{1}, roi_ms1{2});
phi_rcp_ms1 = angle(imresize(exp(1i * phi_ms1_raw), target_size, 'bicubic'));

% Metasurface 2 ROI 提取与重采样
phi_ms2_raw = sample_phase(roi_ms2{1}, roi_ms2{2});
phi_rcp_ms2 = angle(imresize(exp(1i * phi_ms2_raw), target_size, 'bicubic'));

%% ==================== 6. 结果可视化 ====================
figure('Name', 'Phase Analysis Results');
subplot(1,2,1);
imagesc(phi_rcp_ms1); cb1 = colorbar; colormap jet;
title('Metasurface 1 Interpolated Phase');
xlabel('Pixels'); ylabel('Pixels');

subplot(1,2,2);
imagesc(phi_rcp_ms2); cb2 = colorbar; colormap jet;
title('Metasurface 2 Interpolated Phase');
xlabel('Pixels'); ylabel('Pixels');

% 如果需要保存数据，可以取消下行的注释
% writematrix(phi_rcp_ms2, 'phi_rcp_ms2_output.csv');