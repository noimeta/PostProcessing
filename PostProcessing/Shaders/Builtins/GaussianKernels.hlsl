#ifndef UNITY_POSTFX_DISK_KERNELS
#define UNITY_POSTFX_DISK_KERNELS

#if !defined(KERNEL_SMALL) && !defined(KERNEL_MEDIUM) && \
    !defined(KERNEL_LARGE) && !defined(KERNEL_VERYLARGE)

static const int kGaussianSampleCount = 1;
static const float2 kGaussianKernels[kGaussianSampleCount] = { float2(0, 0) };

#endif

#if defined(KERNEL_SMALL)
// 9-tap filters
static const int kGaussianSampleCount = 2;
static const float2 kGaussianKernels[kGaussianSampleCount] = {
	float2(0.0, 0.29411764705882354),
	float2(1.3333333333333333, 0.35294117647058826)
};
#endif

#if defined(KERNEL_MEDIUM)
// 9-tap filters
static const int kGaussianSampleCount = 3;
static const float2 kGaussianKernels[kGaussianSampleCount] = {
	float2(0.0, 0.2270270270),
	float2(1.3846153846, 0.3162162162),
	float2(3.2307692308, 0.0702702703)
};
#endif

#if defined(KERNEL_LARGE)
// 13-tap filters
static const int kGaussianSampleCount = 4;
static const float2 kGaussianKernels[kGaussianSampleCount] = {
	float2(0.0, 0.1964825501511404),
	float2(1.411764705882353, 0.2969069646728344),
	float2(3.2941176470588234, 0.09447039785044732),
	float2(5.176470588235294, 0.010381362401148057)
};
#endif

#if defined(KERNEL_VERYLARGE)
// 17-tap filters
static const int kGaussianSampleCount = 5;
static const float2 kGaussianKernels[kGaussianSampleCount] = {
	float2(0.0, 0.176204109737977),
	float2(1.4285714285714288, 0.2803247200376907),
	float2(3.333333333333333, 0.11089769144348204),
	float2(5.238095238095238, 0.019407096002609356),
	float2(7.142857142857143, 0.0012684376472293698)
};
#endif

#endif // UNITY_POSTFX_DISK_KERNELS
