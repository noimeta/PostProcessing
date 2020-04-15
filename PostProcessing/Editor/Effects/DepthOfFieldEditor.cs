#define Test
using UnityEngine;
using UnityEngine.Rendering.PostProcessing;

namespace UnityEditor.Rendering.PostProcessing
{
    [PostProcessEditor(typeof(DepthOfField))]
    internal sealed class DepthOfFieldEditor : PostProcessEffectEditor<DepthOfField>
    {
        SerializedParameterOverride m_FocusDistance;
#if Test
        SerializedParameterOverride m_FocalRegion;
        SerializedParameterOverride m_NearTransition;
        SerializedParameterOverride m_FarTransition;
#else
        SerializedParameterOverride m_Aperture;
        SerializedParameterOverride m_FocalLength;
        SerializedParameterOverride m_KernelSize;
#endif

        public override void OnEnable()
        {
            m_FocusDistance = FindParameterOverride(x => x.focusDistance);
#if Test
            m_FocalRegion = FindParameterOverride(x => x.focalRegion);
            m_NearTransition = FindParameterOverride(x => x.nearTransition);
            m_FarTransition = FindParameterOverride(x => x.farTransition);
#else
            m_Aperture = FindParameterOverride(x => x.aperture);
            m_FocalLength = FindParameterOverride(x => x.focalLength);
            m_KernelSize = FindParameterOverride(x => x.kernelSize);
#endif
        }

        public override void OnInspectorGUI()
        {
            if (SystemInfo.graphicsShaderLevel < 35)
                EditorGUILayout.HelpBox("Depth Of Field is only supported on the following platforms:\nDX11+, OpenGL 3.2+, OpenGL ES 3+, Metal, Vulkan, PS4/XB1 consoles.", MessageType.Warning);

            PropertyField(m_FocusDistance);
#if Test
            PropertyField(m_FocalRegion);
            PropertyField(m_NearTransition);
            PropertyField(m_FarTransition);
#else
            PropertyField(m_Aperture);
            PropertyField(m_FocalLength);
            PropertyField(m_KernelSize);
#endif
        }
    }
}
