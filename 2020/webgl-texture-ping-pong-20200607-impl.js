
/* This program was written in 6 stages,
 * which basically describes how it works:
 * 1. Draw 6 points.
 * 2. Input a texture to the vertex shader to determine point colors.
 * 3. Use texture input to reference pixel locations to the right,
 *    resulting in the colors shifting left by 1.
 * 4. Have the fragment shader split each point to make the output image
 *    similar to the input texture (but with shifted colors).
 * 5. Render to a small 6x4 texture and display that.
 * 6. Use output texture as input to next frame.
 */

"use strict";

const vertex_shader_text = `
attribute vec3 coordinates;
uniform sampler2D data_texture;
varying vec4 display_color;
varying vec4 texture_uv_encoded;

void main() {
  vec3 screen_coordinates = coordinates * vec3(2.0, 2.0, 1.0);
  screen_coordinates += vec3(-1.0, -1.0, 0.0);
  gl_Position = vec4(screen_coordinates, 1.0);
  gl_PointSize = 2.0;

  vec2 index_uv = coordinates.xy + vec2(-1.0/12.0, 1.0/8.0);
  texture_uv_encoded = texture2DLod(data_texture, index_uv, 0.0);
  vec2 texture_uv;
  texture_uv.x = texture_uv_encoded.x / texture_uv_encoded.y;
  texture_uv.y = texture_uv_encoded.z / texture_uv_encoded.w;
  display_color = texture2DLod(data_texture, texture_uv, 0.0);
}
`

const fragment_shader_text = `
precision highp float;
varying vec4 display_color;
varying vec4 texture_uv_encoded;
void main() {
  if (gl_PointCoord.x < 0.5) {
    gl_FragColor = texture_uv_encoded;
  } else {
    gl_FragColor = display_color;
  }
}
`

const display_vertex_shader_text = `
attribute vec3 rectangle_vertex;
varying vec2 display_uv;
void main() {
  gl_Position = vec4(rectangle_vertex, 1.0);
  if (rectangle_vertex.x < 0.0) {
    display_uv.x = 0.0;
  } else {
    display_uv.x = 1.0;
  }
  if (rectangle_vertex.y < 0.0) {
    display_uv.y = 0.0;
  } else {
    display_uv.y = 1.0;
  }
}
`

const display_fragment_shader_text = `
precision highp float;
uniform sampler2D output_texture;
varying vec2 display_uv;

void main() {
  gl_FragColor = texture2D(output_texture, display_uv, 0.0);
}
`

main();

function log_shader_compile_status(gl, shader) {
  var compiled = gl.getShaderParameter(shader, gl.COMPILE_STATUS);
  console.log('Shader compiled successfully: ' + compiled);
  var compilation_log = gl.getShaderInfoLog(shader);
  console.log('Shader compiler log: ' + compilation_log);
}

function main() {
  /*============== Creating a canvas ====================*/
  var canvas = document.getElementById('glcanvas');
  var gl = canvas.getContext('webgl', { antialias: false });


  /*======== Defining and storing the geometry ===========*/

  const vertices = [
    1/6.0, 3/4.0, 0.0,
    3/6.0, 3/4.0, 0.0,
    5/6.0, 3/4.0, 0.0,
    1/6.0, 1/4.0, 0.0,
    3/6.0, 1/4.0, 0.0,
    5/6.0, 1/4.0, 0.0,
  ];

  // Create a buffer object and store vertices.
  var coordinates_buffer = gl.createBuffer();
  gl.bindBuffer(gl.ARRAY_BUFFER, coordinates_buffer);
  gl.bufferData(gl.ARRAY_BUFFER, new Float32Array(vertices), gl.STATIC_DRAW);
  // Unbind the buffer.
  gl.bindBuffer(gl.ARRAY_BUFFER, null);

  const rectangle_vertices = [
		1.0, 1.0, 0.0,   -1.0, 1.0, 0.0,  -1.0, -1.0, 0.0,
		-1.0, -1.0, 0.0,  1.0, -1.0, 0.0,  1.0,  1.0, 0.0,

  ];
  // Create a buffer object for the trivial texture display.
  var rectangle_vertex_buffer = gl.createBuffer();
  gl.bindBuffer(gl.ARRAY_BUFFER, rectangle_vertex_buffer);
  gl.bufferData(gl.ARRAY_BUFFER, new Float32Array(rectangle_vertices), gl.STATIC_DRAW);
  // Unbind the buffer.
  gl.bindBuffer(gl.ARRAY_BUFFER, null);


  /*========== Texture ===========*/

  // Create input texture.
  const texture_data = [
      7,  12,   3,   8,   255,   0,   0, 255,
     11,  12,   3,   8,     0, 255,   0, 255,
      3,  12,   7,   8,     0,   0, 255, 255,

      7,  12,   3,   8,   255,   0,   0, 255,
     11,  12,   3,   8,     0, 255,   0, 255,
      3,  12,   7,   8,     0,   0, 255, 255,

      7,  12,   7,   8,     0, 255, 255, 255,
     11,  12,   7,   8,   255,   0, 255, 255,
      3,  12,   3,   8,   255, 255,   0, 255,

      7,  12,   7,   8,     0, 255, 255, 255,
     11,  12,   7,   8,   255,   0, 255, 255,
      3,  12,   3,   8,   255, 255,   0, 255,
  ];

  var data_texture = gl.createTexture();
  gl.bindTexture(gl.TEXTURE_2D, data_texture);
  gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA,
    6, 4, 0, gl.RGBA, gl.UNSIGNED_BYTE,
    new Uint8Array(texture_data));

  gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST);
  gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST);
  gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
  gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);
  // Unbind the texture.
  gl.bindTexture(gl.TEXTURE_2D, null);

  // Create output texture.
  var output_texture = gl.createTexture();
  gl.bindTexture(gl.TEXTURE_2D, output_texture);
  gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, 6, 4, 0, gl.RGBA, gl.UNSIGNED_BYTE, null);
  gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST);
  gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST);
  gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
  gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);
  // Unbind the texture.
  gl.bindTexture(gl.TEXTURE_2D, null);

  /*================ Shaders ====================*/

  // Create a vertex shader object
  var vertex_shader = gl.createShader(gl.VERTEX_SHADER);
  gl.shaderSource(vertex_shader, vertex_shader_text);
  gl.compileShader(vertex_shader);
  log_shader_compile_status(gl, vertex_shader);

  // Create fragment shader object
  var fragment_shader = gl.createShader(gl.FRAGMENT_SHADER);
  gl.shaderSource(fragment_shader, fragment_shader_text);
  gl.compileShader(fragment_shader);
  log_shader_compile_status(gl, fragment_shader);

  // Create a shader program object to store
  // the combined shader program
  var shader_program = gl.createProgram();

  // Attach shaders
  gl.attachShader(shader_program, vertex_shader);
  gl.attachShader(shader_program, fragment_shader);

  gl.bindAttribLocation(shader_program, 0, "coordinates");

  // Link both the programs and use them.
  gl.linkProgram(shader_program);

  /*================ Shaders for display ====================*/

  // Create a vertex shader object
  var display_vertex_shader = gl.createShader(gl.VERTEX_SHADER);
  gl.shaderSource(display_vertex_shader, display_vertex_shader_text);
  gl.compileShader(display_vertex_shader);
  log_shader_compile_status(gl, display_vertex_shader);

  // Create fragment shader object
  var display_fragment_shader = gl.createShader(gl.FRAGMENT_SHADER);
  gl.shaderSource(display_fragment_shader, display_fragment_shader_text);
  gl.compileShader(display_fragment_shader);
  log_shader_compile_status(gl, display_fragment_shader);

  // Create a shader program object to store
  // the combined shader program
  var display_shader_program = gl.createProgram();

  // Attach shaders
  gl.attachShader(display_shader_program, display_vertex_shader);
  gl.attachShader(display_shader_program, display_fragment_shader);

  gl.bindAttribLocation(display_shader_program, 0, "rectangle_vertex");

  // Link both the programs and use them.
  gl.linkProgram(display_shader_program);


  //// Avoiding a dumb warning to fill dummy ////////////////////////////////

  gl.enableVertexAttribArray(0);

  //// Associating shaders with buffer objects //////////////////////////////
  gl.useProgram(shader_program);

  // Tell shader that the "data_texture" uniform is bound to texture unit 1.
  var data_texture_uniform = gl.getUniformLocation(shader_program, "data_texture");
  gl.uniform1i(data_texture_uniform, 1);

  gl.useProgram(null);

  //// Associating display shaders and buffers //////////////////////////////
  gl.useProgram(display_shader_program);

  // Tell shader that the "output_texture" uniform is bound to texture unit 2.
  var display_texture_uniform = gl.getUniformLocation(display_shader_program, "output_texture");
  gl.uniform1i(display_texture_uniform, 2);

  gl.useProgram(null);

  /*======= Framebuffer for texture output =======*/
  var output_framebuffer = gl.createFramebuffer();

  /*======= Trivial display shaders and such =======*/

  var frame_count_odd = false;

  function draw_cb() {
    let tmp_input_texture = data_texture;
    let tmp_output_texture = output_texture;
    if (frame_count_odd) {
      tmp_input_texture = output_texture;
      tmp_output_texture = data_texture;
    }

    draw(canvas, gl, output_framebuffer,
      tmp_input_texture, tmp_output_texture,
      shader_program, display_shader_program,
      coordinates_buffer, rectangle_vertex_buffer);

    frame_count_odd = !frame_count_odd;
  }

  document.addEventListener("mousedown", draw_cb);
  draw_cb();
}


function draw(canvas, gl, output_framebuffer,
    input_texture, output_texture,
    shader_program, display_shader_program,
    coordinates_buffer, rectangle_vertex_buffer) {

  // The "data_texture" uniform uses texture unit 1.
  gl.activeTexture(gl.TEXTURE1);
  gl.bindTexture(gl.TEXTURE_2D, input_texture);
  gl.activeTexture(gl.TEXTURE0);

  // The "output_texture" uniform uses texture unit 2.
  gl.activeTexture(gl.TEXTURE2);
  gl.bindTexture(gl.TEXTURE_2D, output_texture);
  gl.activeTexture(gl.TEXTURE0);


  //// Draw to texture ///////////////////////////////////////////////////////
  gl.bindFramebuffer(gl.FRAMEBUFFER, output_framebuffer);
  gl.framebufferTexture2D(
    gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, gl.TEXTURE_2D, output_texture, 0);

  gl.viewport(0, 0, 6, 4);
  gl.clearColor(1.0, 1.0, 1.0, 1.0);
  gl.clear(gl.COLOR_BUFFER_BIT);

  // Switch shader program and attribute array 0.
  // Apparenttly attribute array 0 should always be used.
  gl.useProgram(shader_program);
  gl.bindBuffer(gl.ARRAY_BUFFER, coordinates_buffer);
  gl.vertexAttribPointer(0, 3, gl.FLOAT, false, 0, 0);
  gl.bindBuffer(gl.ARRAY_BUFFER, null);

  gl.drawArrays(gl.POINTS, 0, 6);
  gl.useProgram(null);


  //// Draw to screen ////////////////////////////////////////////////////////
  gl.bindFramebuffer(gl.FRAMEBUFFER, null);
  gl.enable(gl.DEPTH_TEST);
  gl.viewport(0, 0, canvas.width, canvas.height);
  gl.clearColor(1.0, 1.0, 1.0, 1.0);
  gl.clear(gl.COLOR_BUFFER_BIT);

  // Switch shader program and attribute array 0.
  // Apparenttly attribute array 0 should always be used.
  gl.useProgram(display_shader_program);
  gl.bindBuffer(gl.ARRAY_BUFFER, rectangle_vertex_buffer);
  gl.vertexAttribPointer(0, 3, gl.FLOAT, false, 0, 0);
  gl.bindBuffer(gl.ARRAY_BUFFER, null);

  gl.drawArrays(gl.TRIANGLES, 0, 6);
  gl.useProgram(null);
}
