Shader "UI/OutlineColorRotate"
{
    Properties
    {
        [PerRendererData]_MainTex ("Sprite Texture", 2D) = "white" {}
        _Color ("Main Color", Color) = (1,1,1,1)
        _StartColor ("Start Color", Color) = (1, 0, 0, 1)
        _EndColor ("End Color", Color) = (0, 0, 1, 1)
        _BorderThickness ("Border Thickness", Range(0, 0.5)) = 0.05
        _Speed ("Speed", Float) = 1.0
        [MaterialToggle] _Rainbow("Rainbow", Float) = 0
        _Saturation("Rainbow Saturation", Range(0, 1)) = 1.0
        _Brightness("Rainbow Brightness", Range(0, 1)) = 1.0
    }

    SubShader
    {
        Tags {
            "Queue"="Transparent"
            "RenderType"="Transparent"
            "IgnoreProjector"="True"
            "PreviewType"="Plane"
            "CanUseSpriteAtlas"="True"
        }
        
        Pass
        {
            Name "NoMask"
            Tags { "LightMode"="SRPDefaultUnlit" }

            Stencil
            {
                Ref 1
                ReadMask 255
                Comp LEqual
                Pass Keep
            }

            Cull Off
            ZWrite Off
            Blend SrcAlpha OneMinusSrcAlpha
            ColorMask RGBA

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile __ UNITY_UI_CLIP_RECT
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct vert_input { float4 vertex : POSITION; float2 uv : TEXCOORD0; };
            struct pixel_input
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                float2 localUV : TEXCOORD1;
                float4 worldPos : TEXCOORD2;
            };

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            float4 _MainTex_ST;
            float4 _Color, _StartColor, _EndColor;
            float _BorderThickness, _Speed, _Rainbow, _Saturation, _Brightness;
            float4 _ClipRect;

            float NormalizeAngle(float2 p) { float angle = atan2(p.y, p.x); return frac((angle / 6.28318) + 0.5); }

            float3 HueToRGB(float h, float s, float b)
            {
                float3 rgb = saturate(float3(abs(h * 6 - 3) - 1, 2 - abs(h * 6 - 2), 2 - abs(h * 6 - 4)));
                return lerp(float3(1,1,1), rgb, s) * b;
            }

            pixel_input vert(vert_input v)
            {
                pixel_input o;
                o.vertex = TransformObjectToHClip(v.vertex.xyz);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.localUV = v.uv * 2.0 - 1.0;
                o.worldPos = v.vertex;
                return o;
            }

            half4 frag(pixel_input i) : SV_Target
            {
                #ifdef UNITY_UI_CLIP_RECT
                if (any(i.worldPos.xy < _ClipRect.xy) || any(i.worldPos.xy > _ClipRect.zw))
                    discard;
                #endif

                float2 pos = i.localUV;
                float maxAbs = max(abs(pos.x), abs(pos.y));
                float4 texColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv) * _Color;
                
                if (texColor.w <= 0)
                {
                    discard;    
                }

                if (maxAbs < 1.0 - _BorderThickness)
                    return texColor;

                if (_Rainbow == 1.0)
                {
                    float angle = atan2(pos.y, pos.x);
                    float hue = frac((angle / 6.28318) + 0.5 + _Time.y * _Speed);
                    return float4(HueToRGB(hue, _Saturation, _Brightness), 1.0);
                }

                float t = NormalizeAngle(pos) + _Time.y * _Speed;
                t = frac(t);
                float4 outputColor = t > 0.5
                    ? lerp(_StartColor, _EndColor, t)
                    : lerp(_EndColor, _StartColor, t);

                return lerp(float4(1,1,1,1), outputColor, _Saturation) * _Brightness;
            }
            ENDHLSL
        }
    }
}
