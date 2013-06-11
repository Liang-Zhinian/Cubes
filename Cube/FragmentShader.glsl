varying lowp vec4 DestinationColor;
varying lowp float LightIntensity;

void main(void)
{
    lowp vec4 lightColor = vec4(1.0, 1.0, 1.0,1.0);
    gl_FragColor = (DestinationColor *lightColor) * LightIntensity * 0.15;
}