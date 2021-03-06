﻿Shader "UnityShaderTutorial/normal_map" {
    Properties {
        // normal map texture on the material,
        // default to dummy "flat surface" normalmap
        _MainTex ("Texture", 2D) = "white" {}
        _BumpMap("Normal Map", 2D) = "bump" {}
    }
    SubShader {
        Pass {
			Tags { "LightMode" = "ForwardBase" }

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
			#include "UnityLightingCommon.cginc" // for _LightColor0

            struct v2f {
                // these three vectors will hold a 3x3 rotation matrix
                // that transforms from tangent to world space
                half3 tspace0 : TEXCOORD1; // tangent.x, bitangent.x, normal.x
                half3 tspace1 : TEXCOORD2; // tangent.y, bitangent.y, normal.y
                half3 tspace2 : TEXCOORD3; // tangent.z, bitangent.z, normal.z
                // texture coordinate for the normal map
                float2 uv : TEXCOORD4;
                float4 pos : SV_POSITION;

				fixed4 diff : COLOR0; // diffuse lighting color
            };
			
            // vertex shader now also needs a per-vertex tangent vector.
            // in Unity tangents are 4D vectors, with the .w component used to
            // indicate direction of the bitangent vector.
            // we also need the texture coordinate.
            v2f vert (float4 vertex : POSITION, float3 normal : NORMAL, float4 tangent : TANGENT, float2 uv : TEXCOORD0) {
                v2f o;
                o.pos = UnityObjectToClipPos(vertex);
                half3 wNormal = UnityObjectToWorldNormal(normal);
                half3 wTangent = UnityObjectToWorldDir(tangent.xyz);
                // compute bitangent from cross product of normal and tangent
                half tangentSign = tangent.w * unity_WorldTransformParams.w; // -1 또는 1이다. OpenGL과 DirectX의 UV 좌표계 방향이 다르기 때문에 정확하게 방향을 표현할 필요가 있음.
																			 // https://forum.unity.com/threads/what-is-tangent-w-how-to-know-whether-its-1-or-1-tangent-w-vs-unity_worldtransformparams-w.468395/
				half3 wBitangent = cross(wNormal, wTangent) * tangentSign;
                // output the tangent space matrix
                o.tspace0 = half3(wTangent.x, wBitangent.x, wNormal.x);
                o.tspace1 = half3(wTangent.y, wBitangent.y, wNormal.y);
                o.tspace2 = half3(wTangent.z, wBitangent.z, wNormal.z);
                o.uv = uv;

				half nl = max(0, dot(wNormal, _WorldSpaceLightPos0.xyz));
				// factor in the light color
				o.diff = nl * _LightColor0;
                return o;
            }
			
            sampler2D _MainTex;
            sampler2D _BumpMap;
            
            fixed4 frag (v2f i) : SV_Target {
                // sample the normal map, and decode from the Unity encoding
                half3 tnormal = UnpackNormal(tex2D(_BumpMap, i.uv));
                // transform normal from tangent to world space
                half3 worldNormal;
                worldNormal.x = dot(i.tspace0, tnormal);
                worldNormal.y = dot(i.tspace1, tnormal);
                worldNormal.z = dot(i.tspace2, tnormal);
				
                half diff_factor = saturate(dot(worldNormal, _WorldSpaceLightPos0.xyz));
				//float3 viewDirection = normalize(UnityWorldSpaceViewDir(i.pos));
				//half diff_factor = saturate(dot(worldNormal, -viewDirection));

				fixed4 c = tex2D(_MainTex, i.uv);
				c.rgb *= i.diff; // light color
				c.rgb *= diff_factor;
                return c;
            }
            ENDCG
        }
    }
}