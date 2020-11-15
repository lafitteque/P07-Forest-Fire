// This is a simulation of a forest fire
// The simulation shows the propagation of a fire on a map (left) and the temperatures on another one (right)
// When a cell of forest is completely burned, the temperature is considered to be the initial temperature

// Screen and grid parameters
int screenWidth = 800;
int gridWidth = 800;
int cellWidth;

// To know if the simulation is running
int activation = 0;

// Temperature maps
float[][] temperature;
float[][] previousTemperature;

float initialTemperature = 20;

// To know if a cell of forest is burning
boolean[][] burning;

// Forest maps
float[][] forest;
float[][] nextForest;

// Equation parameters
float deltaTime = 1;
float k = 0.004;
float deltaNoise = 0.02;
float rho = 0.1;
float H0 = 1600;
float capacity = 0.5;
float D = 0.01;
float h = 0.4;

float temperatureThreshold = 150;
float temperatureBeginFire = 300;



void setup(){
  frameRate(60);
  size(1600,800);
  background(100,100,100);
  
  init();

  drawForest(forest);
}


void init(){
  // Initialize the maps of temperature, burning, and forest
  
  temperature = new float[gridWidth][gridWidth];
  previousTemperature = new float[gridWidth][gridWidth];
  
  forest = new float[gridWidth][gridWidth];
  
  burning = new boolean[gridWidth][gridWidth];
  
  cellWidth = (int) ((float)screenWidth/gridWidth);

  for (int i=0; i<gridWidth;i++){
    for (int j =0; j<gridWidth;j++){
      temperature[i][j] = initialTemperature;
      previousTemperature[i][j] = initialTemperature;
    }
  }
    
  // We set the forest elements  with perlin noise. The model only uses one layer of perlin noise
  // But we could do multiple layers with different frequencies and magnitudes 
  // For example  the sum of A/i * noise(freq*i)
  // Which can be seen as adding detail (high frequencies and low magnitude) with each layer
  // This method is used for procedural terain generation
  for (int i=1; i<gridWidth-1;i++){
    for (int j =1; j<gridWidth-1;j++){
      forest[i][j] = noise(deltaNoise *  j , deltaNoise * i);
    }
  }
  
  // We set the borders with no forest (this is to avoid problems when calculating the elements on each border.
  for (int i=0; i<gridWidth;i++){    
    forest[i][0] = 0;
    forest[i][gridWidth-1] = 0;
    forest[gridWidth-1][i] = 0;
    forest[0][i] = 0;
  }  
}



void beginFire(){
  if (mousePressed){
    
    // Begin a fire in a square
    int squareSize = 5;
    for (int i= -squareSize / 2 ; i < squareSize / 2 + 1 ; i++){
      for (int j =-squareSize / 2 ; j< squareSize / 2 + 1 ; j++){
        temperature[(int)((float)mouseX/cellWidth) + i][(int)((float)mouseY/cellWidth)+ j] = temperatureBeginFire;
      }
    }
    
  }
}



void drawForest(float[][] forest){
  
  loadPixels();
  for (int i = 0; i < gridWidth; i++) {
    for (int j = 0; j < gridWidth; j ++) {
      
      // To increase the performance, I decided to draw the squares manually instead of using processing pre-implemented rect function
      for (int x = 0 ; x<cellWidth ; x++){
        for (int y = 0 ;y<cellWidth ; y++){   
          
          // We draw the forest on the left
          
          int pos_forest =(j*cellWidth + y) * screenWidth * 2 + (i * cellWidth + x) ;
          pixels[pos_forest] = color(0 , forest[i][j]*255 , 0);
          
          // We draw the forest on the right
          int pos_temp = (j*cellWidth + y)* screenWidth * 2  + (i * cellWidth + x +screenWidth) ; 
          pixels[pos_temp] = color((temperature[i][j])/600*255 , 0 , 255-(temperature[i][j])/600*255);
        }
      }  
      
    }
  }
  updatePixels();
  
  // A less optimized way to do it would be as follow:
  
  //for (int i=0; i<gridWidth;i++){
  //  for (int j =0; j<gridWidth;j++){
  //      push();
  //      noStroke();
  //      fill((temperature[i][j])/300*255 , 0 , 255-(temperature[i][j])/300*255);
  //      rect(800+cellWidth*i,cellWidth*j,cellWidth,cellWidth);
  //      pop();      
  //      if (temperature[i][j] > 100){
  //       // println(temperature[i][j]);
  //      }
        
  //      push();
  //      noStroke();
  //      fill(0 , forest[i][j]*255 , 0);
  //      rect(cellWidth*i,cellWidth*j,cellWidth,cellWidth);
  //      pop();      
      
  //  }
  //}
  
}


void draw(){
  beginFire();
  
  nextTemperature();
  
  calcule_bois();

  drawForest(forest);
}


void calcule_bois(){
  
  for (int i = 0 ; i < gridWidth ; i++){
    for (int j = 0 ; j < gridWidth; j++){
      
      // The wood in each cell decreases when it is burning
      if(burning[i][j] || (temperature[i][j] > temperatureThreshold && forest[i][j] > 0)){
        burning[i][j] = true;
        forest[i][j] -= k*deltaTime;
        forest[i][j] = max(0 , forest[i][j]);
      }   
      
      // If there is no wood left, the cell stops burning
      if (forest[i][j] == 0 || temperature[i][j]<150){
        burning[i][j] = false;
      }
      
    }
  }
  
}


void nextTemperature(){
    for (int i = 1 ; i < gridWidth-1 ; i++){
      for (int j = 1 ; j<gridWidth-1; j++){
        
        // Equations of propagation and combustion
        if (burning[i][j]){
        temperature[i][j] =   previousTemperature[i][j] 
                              + deltaTime *( 
                                              forest[i][j]*H0/rho/capacity // The temperature increases more when there is more wood left 
                                              - h*(previousTemperature[i][j]-initialTemperature)  // The temperature naturally decreases with time (the energy is dissipated)
                                              + D * laplacian(previousTemperature , i , j)  // Propagation
                                            );  
        }
        else{
                  temperature[i][j] += deltaTime *(
                                                    -h*(previousTemperature[i][j]-initialTemperature) 
                                                    +D * laplacian(previousTemperature , i , j)
                                                   );  
        }
      }
    }
    
    float[][] temp = temperature;
    previousTemperature = temp;
    
}


float laplacian (float[][] matrix , int i , int j){
  // The choice here was to consider the corners (diagonals) and weight them with lower values 
  return (0.2*matrix[i+1][j] +0.2*matrix[i][j+1] +0.2*matrix[i-1][j]+0.2*matrix[i][j-1]
                                                    + 0.05*matrix[i+1][j+1] +0.05*matrix[i-1][j+1] +0.05*matrix[i-1][j-1]+0.05*matrix[i+1][j-1]- 8 * matrix[i][j]) ;
}
