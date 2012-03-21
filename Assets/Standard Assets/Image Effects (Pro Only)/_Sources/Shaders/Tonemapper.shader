Shader "Hidden/Tonemapper" {
	Properties {
		_MainTex ("", 2D) = "black" {}
		_SmallTex ("", 2D) = "grey" {}
		_Curve ("", 2D) = "black" {}
	}
	
	// Shader code pasted into all further CGPROGRAM blocks
	CGINCLUDE
	
	#include "UnityCG.cginc"
	 
	struct v2f {
		float4 pos : POSITION;
		float2 uv : TEXCOORD0;
	};
	
	sampler2D _MainTex;
	sampler2D _SmallTex;
	sampler2D _Curve;
	
	float4 _HdrParams;
	float2 intensity;
	float4 _MainTex_TexelSize;
	float _AdaptionSpeed;
	float _ExposureAdjustment;
	float _RangeScale;
	float _SCurveScale;
	
	v2f vert( appdata_img v ) 
	{
		v2f o;
		o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
		o.uv = v.texcoord.xy;
		return o;
	} 

	half4 fragLog(v2f i) : COLOR 
	{
		const float DELTA = 0.0001f;
 
		float fLogLumSum = 0.0f;
 
		fLogLumSum += log( Luminance(tex2D(_MainTex, i.uv + _MainTex_TexelSize.xy * half2(-1,-1)).rgb) + DELTA);		
		fLogLumSum += log( Luminance(tex2D(_MainTex, i.uv + _MainTex_TexelSize.xy * half2(1,1)).rgb) + DELTA);		
		fLogLumSum += log( Luminance(tex2D(_MainTex, i.uv + _MainTex_TexelSize.xy * half2(-1,1)).rgb) + DELTA);		
		fLogLumSum += log( Luminance(tex2D(_MainTex, i.uv + _MainTex_TexelSize.xy * half2(1,-1)).rgb) + DELTA);		

		half avg = fLogLumSum / 4.0;
		return half4(avg,avg,avg, avg);
	}

	half4 fragExpNoBlend(v2f i) : COLOR 
	{
		float lum = 0.0f;
		
		lum += tex2D(_MainTex, i.uv  + _MainTex_TexelSize.xy * half2(-1,-1)).x;	
		lum += tex2D(_MainTex, i.uv  + _MainTex_TexelSize.xy * half2(1,1)).x;	
		lum += tex2D(_MainTex, i.uv + _MainTex_TexelSize.xy * half2(1,-1)).x;	
		lum += tex2D(_MainTex, i.uv  + _MainTex_TexelSize.xy * half2(-1,1)).x;	

		lum = exp(lum / 4.0f);
		
		return float4(lum, lum, lum, 1.0);
	}

	half4 fragExp(v2f i) : COLOR 
	{
		float lum = 0.0f;
		
		lum += tex2D(_MainTex, i.uv  + _MainTex_TexelSize.xy * half2(-1,-1)).x;	
		lum += tex2D(_MainTex, i.uv  + _MainTex_TexelSize.xy * half2(1,1)).x;	
		lum += tex2D(_MainTex, i.uv + _MainTex_TexelSize.xy * half2(1,-1)).x;	
		lum += tex2D(_MainTex, i.uv  + _MainTex_TexelSize.xy * half2(-1,1)).x;	

		lum = exp(lum / 4.0f);
		
		return float4(lum, lum, lum, saturate(0.0125 * _AdaptionSpeed));
	}
			
	half3 ToCIE(float3 FullScreenImage)
	{
		// RGB -> XYZ conversion 
		// http://www.w3.org/Graphics/Color/sRGB 
		// The official sRGB to XYZ conversion matrix is (following ITU-R BT.709)
		// 0.4125 0.3576 0.1805
		// 0.2126 0.7152 0.0722 
		// 0.0193 0.1192 0.9505 
		 
		float3x3 RGB2XYZ = {0.5141364, 0.3238786, 0.16036376, 0.265068, 0.67023428, 0.06409157, 0.0241188, 0.1228178, 0.84442666};
		 
		float3 XYZ = mul(RGB2XYZ, FullScreenImage.rgb); 
		 
		// XYZ -> Yxy conversion 
		 
		float3 Yxy; 
		 
		Yxy.r = XYZ.g; 
		 
		// x = X / (X + Y + Z) 
		// y = X / (X + Y + Z) 
		 
		float temp = dot(float3(1.0,1.0,1.0), XYZ.rgb); 
		 
		Yxy.gb = XYZ.rg / temp;	
		
		return Yxy;	
	}		
	
	half3 FromCIE(float3 Yxy)
	{	
		float3 XYZ;
		// Yxy -> XYZ conversion 
		XYZ.r = Yxy.r * Yxy.g / Yxy. b; 
		 
		// X = Y * x / y 
		XYZ.g = Yxy.r;
		 
		// copy luminance Y 
		XYZ.b = Yxy.r * (1 - Yxy.g - Yxy.b) / Yxy.b;
		 
		// Z = Y * (1-x-y) / y 
		 
		// XYZ -> RGB conversion 
		// The official XYZ to sRGB conversion matrix is (following ITU-R BT.709) 
		// 3.2410 -1.5374 -0.4986
		// -0.9692 1.8760 0.0416 
		// 0.0556 -0.2040 1.0570 
 
 		float3x3 XYZ2RGB = { 2.5651,-1.1665,-0.3986, -1.0217, 1.9777, 0.0439, 0.0753, -0.2543, 1.1892};		

		return mul(XYZ2RGB, XYZ);
	}
			
	half4 frag(v2f i) : COLOR 
	{
		half avgLum = tex2D(_SmallTex, i.uv).x;
		half4 color = tex2D (_MainTex, i.uv);
		
		half3 cie = ToCIE(color.rgb);
		
		float lumScaled = cie.r * _HdrParams.z / (0.001 +	avgLum);
		
		// mh
		lumScaled = (lumScaled * (1.0f + lumScaled / (_HdrParams.w)))/(1.0f + lumScaled);
		
		cie.r = lumScaled; 
		
		color.rgb = FromCIE(cie);
		return color;
		
		/*
		half avgLum = tex2D(_SmallTex, i.uv).x;
		half4 color = tex2D (_MainTex, i.uv);
		
		half range = _HdrParams.z;
		half4 minLum = 0;
		half4 maxLum = avgColor + range/2.0;
		color = (color - minLum) / (maxLum - minLum);
		
		return color;
		*/
		return 0;
	}
	
	half4 fragCurve(v2f i) : COLOR 
	{
		half4 color = tex2D(_MainTex, i.uv);
		half3 cie = ToCIE(color.rgb);
		
		// Remap to new lum range
		half newLum = tex2D(_Curve, half2(cie.r * _RangeScale, 0.5)).r;
		cie.r = newLum; 
		color.rgb = FromCIE(cie);
		
		return color;		
	}	
	
	half4 fragUncharted(v2f i) : COLOR
	{
		const float A = 0.15;
		const float B = 0.50;
		const float C = 0.10;
		const float D = 0.20;
		const float E = 0.02;
		const float F = 0.30;
		const float W = 11.2;

		float3 texColor = tex2D(_MainTex, i.uv).rgb;
		texColor *= _ExposureAdjustment;

		float ExposureBias = 2.0;
		float3 x = ExposureBias*texColor;
		float3 curr = ((x*(A*x+C*B)+D*E)/(x*(A*x+B)+D*F))-E/F;
		
		x = W;
		float3 whiteScale = 1.0f/(((x*(A*x+C*B)+D*E)/(x*(A*x+B)+D*F))-E/F);
		float3 color = curr*whiteScale;

		// float3 retColor = pow(color,1/2.2);

		return half4(color, 1.0);		
	}

	// we are doing it on luminance here (better color preservation, but some other problems like very fast saturation)
	float4 fragSimpleReinhard(v2f i) : COLOR
	{
		float4 texColor = tex2D(_MainTex, i.uv);
		float lum = Luminance(texColor.rgb);
		float lumTm = lum * _ExposureAdjustment;
		float scale = lumTm / (1+lumTm);  
		return float4(texColor.rgb * scale / lum, texColor.a);
	}
	
	float4 fragOptimizedHejiDawson(v2f i) : COLOR 
	{

		float4 texColor = tex2D(_MainTex, i.uv );
		texColor *= _ExposureAdjustment;
		float4 X = max(half4(0.0,0.0,0.0,0.0), texColor-0.004);
		float4 retColor = (X*(6.2*X+.5))/(X*(6.2*X+1.7)+0.06);
		return retColor*retColor;
	}		

	float4 fragPhotographic(v2f i) : COLOR
	{
		float4 texColor = tex2D(_MainTex, i.uv);
		return 1-exp2(-_ExposureAdjustment * texColor);
	}
	
	ENDCG 
	
Subshader {
 Pass {
	  ZTest Always Cull Off ZWrite Off
	  Fog { Mode off }      

      CGPROGRAM
      #pragma fragmentoption ARB_precision_hint_fastest 
      #pragma vertex vert
      #pragma fragment frag
      ENDCG
  }

 Pass {
	  ZTest Always Cull Off ZWrite Off
	  Fog { Mode off }      

      CGPROGRAM
      #pragma fragmentoption ARB_precision_hint_fastest 
      #pragma vertex vert
      #pragma fragment fragLog
      ENDCG
  }  
 Pass {
	  ZTest Always Cull Off ZWrite Off
	  Fog { Mode off }      

	 Blend SrcAlpha OneMinusSrcAlpha

      CGPROGRAM
      #pragma fragmentoption ARB_precision_hint_fastest 
      #pragma vertex vert
      #pragma fragment fragExp
      ENDCG
  }  
 Pass {
	  ZTest Always Cull Off ZWrite Off
	  Fog { Mode off }      

      CGPROGRAM
      #pragma fragmentoption ARB_precision_hint_fastest 
      #pragma vertex vert
      #pragma fragment fragExpNoBlend
      ENDCG
  }  
  
  // 4 user controllable tonemap curve
  Pass {
	  ZTest Always Cull Off ZWrite Off
	  Fog { Mode off }      

      CGPROGRAM
      #pragma fragmentoption ARB_precision_hint_fastest 
      #pragma vertex vert
      #pragma fragment fragCurve
      ENDCG
  }  

  // 5 tonemapping in uncharted
  Pass {
	  ZTest Always Cull Off ZWrite Off
	  Fog { Mode off }      

      CGPROGRAM
      #pragma fragmentoption ARB_precision_hint_fastest 
      #pragma vertex vert
      #pragma fragment fragUncharted
      ENDCG
  }  

  // 6 simple tonemapping based reinhard
  Pass {
	  ZTest Always Cull Off ZWrite Off
	  Fog { Mode off }      

      CGPROGRAM
      #pragma fragmentoption ARB_precision_hint_fastest 
      #pragma vertex vert
      #pragma fragment fragSimpleReinhard
      ENDCG
  }  

  // 7 OptimizedHejiDawson
  Pass {
	  ZTest Always Cull Off ZWrite Off
	  Fog { Mode off }      

      CGPROGRAM
      #pragma fragmentoption ARB_precision_hint_fastest 
      #pragma vertex vert
      #pragma fragment fragOptimizedHejiDawson
      ENDCG
  }  
  
  // 8 Photographic
  Pass {
	  ZTest Always Cull Off ZWrite Off
	  Fog { Mode off }      

      CGPROGRAM
      #pragma fragmentoption ARB_precision_hint_fastest 
      #pragma vertex vert
      #pragma fragment fragPhotographic
      ENDCG
  }    
 
}

Fallback off
	
} // shader