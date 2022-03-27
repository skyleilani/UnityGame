// shader based on https://www.youtube.com/watch?v=kY7liQVPQSc
//  z = z^2+c

Shader "Explorer/Mandelbrot"
{
    // required data for shader to function properly
    // there are 
    Properties
    {
        // 2D texture/image
        _MainTex("Texture", 2D) = "white" {}

        // holds area we will render (center, center, size, size) 
        _Area("Area", vector) = (0, 0, 4 , 4)

            // range of -pi to pi in radians
            _Angle("Angle", range(-3.1415, 3.1415)) = 0

            _MaxIter("Iterations", range(4, 1000)) = 255

            _Color("Color", range(0,1)) = .5

            _Repeat("Repeat", float) = 1
            _Speed("Speed", float) = 1
            _Symmetry("Symmetry", range(0,1)) = 1


    }
    SubShader
    {
        // No culling or depth
        Cull Off ZWrite Off ZTest Always

        // render to screen
        // shader code down here
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            // struct for vertex shader
            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            // vertex shader function
            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            // instantiate 
            float4 _Area;
           
            float _MaxIter, _Angle, _Color, _Repeat, _Speed, _Symmetry;
            sampler2D _MainTex;

            // function rotate point in 2d space 
            // og_p - original point
            // piv_p -pivot point around w      // a - angle
            float2 rotate(float2 og_p, float piv_p, float a) {

                float s = sin(a);
                float c = cos(a);

                // set og_p to 00
                og_p -= piv_p;

                // rotate the original point 
                // new x = original point's X * cosine(angle) - original point's Y *sin(angle) 
                // new y = original point's X * sin(angle) + original point's Y * cosine(angle) 
                og_p = float2(og_p.x * c - og_p.y * s, og_p.x * s + og_p.y * c);

                // shift back to original pivot after rotation is done
                og_p += piv_p;

                return og_p;
            }

            // fragment shadder
            fixed4 frag(v2f i) : SV_Target
            {

                // start position of pixel, initialized to uv coordinate. 
                float2 uv = i.uv - .5; // uv centered around origin 
                // four fold symmetry 
                uv = abs(uv);
                uv = rotate(uv, 0, .25 * 3.14159265);
                uv = abs(uv);

                uv = lerp(i.uv - .5, uv, _Symmetry);

                float2 C = _Area.xy + uv* _Area.zw; 
                C = rotate(C, _Area.xy, _Angle);

                float r = 50; // escape radius 
                float r_sq = r * r; 


                // current location of pixel moving across screen
                float2 z, zPrev;
                

                for (float i = 0; i < 255; i++) {
                    zPrev = rotate(z, 0, _Time.y);
                    z = float2(z.x * z.x - z.y * z.y, 2 * z.x * z.y) + C;
                    // breakout of loop
                    if (dot(z, zPrev) > r) break; 
                }
                
                if (i > _MaxIter) return 0;

                float dO = length(z); // distance from origin of circle 
                float iter = (dO - r) / (r_sq - r) *.5 + .5 ; // distance now has a range of 0-1
                iter = log2(log(dO) / log(r)); // shift gradient; doube exponential interpolation
                //i += iter;

                float m = sqrt(i / _MaxIter);

                float4 rgba = sin(float4(.98f,(m * .3f)*.5 + .5, .65f, 1)*m*20)*.5+.5 ;
                rgba = tex2D(_MainTex, float2(m * _Repeat + _Time.y * _Speed, _Color));

                float angle = atan2(z.x, z.y); // define new angle to change over time from -pi to pi 
                rgba *= smoothstep(4,0,iter); 

                rgba *= 1 + sin(angle * 2+ _Time.y*4)*.2; // leaves move at same speed
                                                        
                return rgba;
            }
            ENDCG
        }
    }
}
