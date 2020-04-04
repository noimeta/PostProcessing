using UnityEngine.Rendering.PostProcessing;

namespace UnityEditor.Rendering.PostProcessing
{
    [PostProcessEditor(typeof(Bloom))]
    internal sealed class BloomEditor : PostProcessEffectEditor<Bloom>
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
            EditorUtilities.DrawHeaderLabel("Bloom");

            PropertyField(m_Intensity);
            PropertyField(m_Threshold);
            PropertyField(m_Bluriness);
        }
    }
}
