import java.util.List;
import java.util.Vector;
import toxi.geom.*;
import toxi.geom.mesh2d.Voronoi;


import ddf.minim.*;
import ddf.minim.analysis.*;
import ddf.minim.spi.*; 
import com.hamoid.*; 

VideoExport videoExport; 

Minim minim;
AudioPlayer song;
FFT fft;


//input path to song (audio
//String song_path = "SONG PATH";, replace with path to .wav
String song_path = "SONG PATH";


//separator for input text file
String SEP = "|";
//set frames per second to be rendered
float movieFPS = 30;
float frameDuration = 1 / movieFPS;
BufferedReader reader;



//TODO modify this to take 5 frame rolling average or something similar
// Variables which define the "zones" of the spectrum
// For example, for bass, we only take the first 4% of the total spectrum
float specLow = 0.03; // 3%
float specMid = 0.125;  // 12.5%
float specHi = 0.20;   // 20%

// Score values ​​for each zone
float scoreLow = 0;
float scoreMid = 0;
float scoreHi = 0;

// Previous value, to soften the reduction
float oldScoreLow = scoreLow;
float oldScoreMid = scoreMid;
float oldScoreHi = scoreHi;

// Softening value
float scoreDecreaseRate = 25;

List<Vec2D> points;
int veclength;
java.util.Random rnd;
float r;
float jitterDecay = 10.0;
float scaleY = 10.0;

//r = random(-5, 5);


void setup() {
  size(800, 600);
  noFill();
  points = new ArrayList<Vec2D>();
  int n_points = 1;
  for (int i=0; i<n_points; i++) {
    points.add( new Vec2D(random(width), random(height)));
  }
  
  
  // Bring in from  VideoExport example
  // Produce the video as fast as possible
  frameRate(1000);
  reader = createReader(song_path + ".txt");
  videoExport = new VideoExport(this);
  videoExport.setFrameRate(movieFPS);
  videoExport.setAudioFileName(song_path);
  videoExport.startMovie();

}
void draw() {
  //Read in .txt line to "line"
  String line;
  try {
    line = reader.readLine();
  }
  catch (IOException e) {
    e.printStackTrace();
    line = null;
  }
  if (line == null) {
    // Done reading the file.
    // Close the video file.
    videoExport.endMovie();
    exit();
  } else {
    String[] p = split(line, SEP);
    // The first column indicates 
    // the sound time in seconds.
    float soundTime = float(p[0]);

    while (videoExport.getCurrentTime() < soundTime + frameDuration * 0.5) {
      //background(0); in Cubes background color is modified by sound intensity
      
      
      // Calculation of the "scores" (power) for three categories of sound
      // First, save the old values
      oldScoreLow = scoreLow;
      oldScoreMid = scoreMid;
      oldScoreHi = scoreHi;

      // Reset the values
      scoreLow = 0;
      scoreMid = 0;
      scoreHi = 0;

      for (int i=1; i<p.length; i++) {
        float value = float(p[i]);
        if (i <= p.length*specLow) {
          scoreLow += value;
        } else if (i <= p.length*specMid) {
          scoreMid += value;
        } else {
          scoreHi += value;
        }
      } 
   

        if (scoreLow > oldScoreLow & points.size()<40) {
        for(int i=0;i<3;i++){
        points.add(new Vec2D(random(width/2-width/4,width/2+width/4), random(height/2-height/4,height/2+height/4)));
        delay(5); 
        }
      } else if(scoreLow<=oldScoreLow & points.size()>10){
        //points.subList(1,5).clear();
        for(int i=0;i<2;i++){
        points.subList(1,2).clear();
        delay(5); 
      }
      }
   
      // Slow down the descent.
      if (oldScoreLow > scoreLow) {
        scoreLow = oldScoreLow - scoreDecreaseRate;
      }

      if (oldScoreMid > scoreMid) {
        scoreMid = oldScoreMid - scoreDecreaseRate;
      }

      if (oldScoreHi > scoreHi) {
        scoreHi = oldScoreHi - scoreDecreaseRate;
      }
      
      // Subtle background color TODO, update to stroke color?
      //background(scoreLow/100, scoreMid/100, scoreHi/100);
      
      float previousBandValue = float(p[1]);      
      
      background(0);
      stroke(235, 64, 52);
      Voronoi voronoi = new Voronoi();
      voronoi.addPoints(points);
      Rect bound_rect = new Rect(0, 0, width, height);
      SutherlandHodgemanClipper clipper = new SutherlandHodgemanClipper(bound_rect);
      List<Polygon2D> regions = voronoi.getRegions();
      for (int i=0; i<regions.size(); i++) {
        regions.set(i, clipper.clipPolygon(regions.get(i)));
        
        
        //This applies jitter to the centroid point
        Vec2D centroid = regions.get(i).getCentroid().jitter(0.0,jitterDecay);
        //Vec2D centroid = regions.get(i).getCentroid().jitter(0.0,4.0);
        points.set(i, centroid);
      }
      drawPoints(points);
      drawPolygons(regions);
      
      veclength = points.size();
      println("Length: ",veclength);
      //print(points.get(points.size()-1));
      
      //decrease jitter over time
      if(jitterDecay>0.0){
        jitterDecay=-0.1;
      }
     
      
     videoExport.saveFrame(); 
    }
  }
}

void drawPoints(List<Vec2D> pts) {
  for (Vec2D p : pts)
    ellipse(p.x, p.y, 2, 2);
}
void drawPolygons(List<Polygon2D> ps) {
  for (Polygon2D p : ps)
    drawPolygon(p);
}
void drawPolygon(Polygon2D p) {
  beginShape();
  for (Vec2D v : p.vertices)
    vertex(v.x, v.y);
  endShape(CLOSE);
}
/*void mousePressed() {
  points.add(new Vec2D(mouseX, mouseY));
  if(jitterDecay<10){
  jitterDecay++;
  }
}
void mouseDragged() {
  points.add(new Vec2D(mouseX, mouseY));
  if(jitterDecay<10){
  jitterDecay++;
  }
}*/
