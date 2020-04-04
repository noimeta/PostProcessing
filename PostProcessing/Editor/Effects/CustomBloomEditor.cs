using UnityEngine.Rendering.PostProcessing;

namespace UnityEditor.Rendering.PostProcessing
{
    [PostProcessEditor(typeof(CustomBloom))]
    internal sealed class CustomBloomEditor : PostProcessEffectEditor<CustomBloom>
    {
        SerializedParameterOverride m_Intensity;
        SerializedParameterOverride m_Threshold;
        SerializedParameterOverride m_Bluriness;

        public override void OnEnable()
        {
            m_Intensity = FindParameterOverride(x => x.intensity);
            m_Threshold = FindParameterOverride(x => x.threshold);
            m_Bluriness = FindParameterOverride(x => x.bluriness);
        }

        public override void OnInspectorGUI()
        {
            EditorUtilities.DrawHeaderLabel("CustomBloom");

            PropertyField(m_Intensity);
            PropertyField(m_Threshold);
            PropertyField(m_Bluriness);
        }
    }
}
