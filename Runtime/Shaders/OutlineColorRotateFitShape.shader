Shader "UI/OutlineColorRotateFitShape"
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
        
        // no mask shader
        Pass
        {
            Name "NoMask"
            Tags { "LightMode"="SRPDefaultUnlit" }

            Stencil
            {
                Ref 0
                Comp Always
                Pass Keep
            }

            Cull Off
            ZWrite Off
            Blend SrcAlpha OneMinusSrcAlpha
            ColorMask RGBA

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
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
                float4 texColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv) * _Color;
                float alpha = texColor.a;
            
                if (alpha <= 0)
                    discard;
            
                float2 pixelSize = float2(ddx(i.uv.x), ddy(i.uv.y)) * _BorderThickness;

                _BorderThickness *= 0.5;
                
                float2 left = i.uv + float2(-pixelSize.x - _BorderThickness, 0);
                float2 right = i.uv + float2(pixelSize.x + _BorderThickness, 0);
                float2 up = i.uv + float2(0, pixelSize.y + _BorderThickness);
                float2 down = i.uv + float2(0, -pixelSize.y - _BorderThickness);
                
                float alphaLeft   = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, left).a;
                float alphaRight  = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, right).a;
                float alphaUp     = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, up).a;
                float alphaDown   = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, down).a;
            
                float edge = step(0.5, alpha - alphaLeft) +
                             step(0.5, alpha - alphaRight) +
                             step(0.5, alpha - alphaUp) +
                             step(0.5, alpha - alphaDown);
            
                if (edge > 0)
                {
                    if (_Rainbow == 1.0)
                    {
                        float angle = atan2(i.localUV.y, i.localUV.x);
                        float hue = frac((angle / 6.28318) + 0.5 + _Time.y * _Speed);
                        return float4(HueToRGB(hue, _Saturation, _Brightness), 1.0);
                    }
            
                    float t = NormalizeAngle(i.localUV) + _Time.y * _Speed;
                    t = frac(t);
                    float4 outputColor = t > 0.5
                        ? lerp(_StartColor, _EndColor, t)
                        : lerp(_EndColor, _StartColor, t);
            
                    return lerp(float4(1,1,1,1), outputColor, _Saturation) * _Brightness;
                }
            
                return texColor;
            }
            ENDHLSL
        }
    }
}
