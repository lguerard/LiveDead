macro "LiveDeadAnalysis" {
/* Batch analysis of LiveDead stained bacteria. The images need to be 2D images with two channels (Syto9/green and PI/red) 
 * saved in Carl Zeiss raw data format (either *.lsm or *.czi). All images in a specific folder will be analyzed and the 
 * results (Syto9 area, PI area and double positive area for each image) saved in a tab delimited text file.  
 * 
 * Instructions:
 * Open the image to segment and run the macro.
 * The resulting images and analysis results are found in the folder ../GC_Results
 * 
 * Macro created by Maria Smedh and Laurent , Centre for Cellular Imaging 
 * 151112 Version 1.0
 */
 
setBatchMode(true);
run("Close All");
print("\\Clear");
roiManager("Reset");
run("Clear Results");
print("-----------------------------------");
print("LiveDeadAnalysis macro started");

//Get the date
getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);
if ((month>=10) && (dayOfMonth<10)) 
{
	trueYear = ""+year;
	trueMonth = ""+month+1;
	trueDay = "0"+dayOfMonth;
	print("Date: "+year+"-"+month+1+"-0"+dayOfMonth);
}
else if ((month<10) && (dayOfMonth<10)) 
{
	trueYear = ""+year;
	trueMonth = "0"+month+1;
	trueDay = "0"+dayOfMonth;
	print("Date: "+year+"-0"+month+1+"-0"+dayOfMonth);
}
else if ((month<10) && (dayOfMonth>10)) 
{
	trueYear = ""+year;
	trueMonth = "0"+month+1;
	trueDay = ""+dayOfMonth;
	print("Date: "+year+"-0"+month+1+"-"+dayOfMonth);
}
else 
{
	trueYear = ""+year;
	trueMonth = ""+month+1;
	trueDay = ""+dayOfMonth;
	print("Date: "+year+"-"+month+1+"-"+dayOfMonth);
}

//--------------------------------------------------------
// Initial settings:
//--------------------------------------------------------
run("Colors...", "foreground=white background=black selection=yellow");
//run("Set Measurements...", "area mean min centroid display redirect=None decimal=4");
run("Set Measurements...", "area centroid shape display redirect=None decimal=4");
run("Options...", "iterations=1 count=1 black edm=Overwrite"); //Black background in binary images

//--------------------------------------------------------
//Get file/folder information:
Folder = getDirectory("Choose the folder where your images are located");
	OutputFolderName = "LiveDeadResults";
	Output_Folder = Folder + File.separator+ OutputFolderName;
	File.makeDirectory(Output_Folder);
	File.makeDirectory(Output_Folder+File.separator+"ResultImages");
	
	Files = getFileList(Folder);
	Array.sort(Files);
	NrOfFiles = Files.length;
	NrOfImages = 0;
	roiNumber = newArray(2);
	roiNumber[0] = 0;
	roiNumber[1] = 0;

	//Get the minimum size for the Particle Analysis plugin
	MinSizeObject = getNumber("What is the minimum size of the object you want to measure ?", 3);

	//Name of the output text file
	TextName = trueYear+trueMonth+trueDay+"AutoSize"+MinSizeObject+".txt";
	//Write the different columns in the text file, separated by tab
	File.saveString("File Name\tGreen Area (px)\tGreen Area (ratio)\tRed Area (px)\tRed Area (ratio)\tTotal Area (px)\r",Output_Folder+File.separator+TextName);

	//Loop through the different files
	for (i=0; i<NrOfFiles; i++) {
		//Only treat tif files
		if (endsWith(Files[i], ".tif"))
		{
			test= 0;

			NrOfImages = NrOfImages + 1;
			ImgName = Files[i];
			StrInd1 = indexOf(ImgName, ".tif");
			//Get the name without the extension
			ShortFileName=substring(ImgName,0, StrInd1);
			//Get the name without the channel information
			ShortFileNameWithoutChannelInfo = substring(ShortFileName,0,lengthOf(ShortFileName)-3);
			FullName = Folder + ImgName;
			open(FullName);
			//Change the properties to pixel
			run("Properties...", "channels=1 slices=1 frames=1 unit=pixel pixel_width=1 pixel_height=1 voxel_depth=1");
			getStatistics(area, mean, min, max);
			//Convert to 32-bit not RGB
			run("32-bit");
			//Auto threshold
			setAutoThreshold("Yen dark");
			//Get the different objects in the file
			
			//If green channel
			if(endsWith(ShortFileName,"c1"))
			{
				print("Treating "+ShortFileNameWithoutChannelInfo+" green channel");
				run("Analyze Particles...", "size="+MinSizeObject+"-Infinity pixel show=Overlay display clear add in_situ");
				ColorArea = 0;
				//Loop through the results
				for(j=0;j<nResults;j++)
					ColorArea = ColorArea + getResult("Area",j);
				//Values for each channel
				values = newArray(4);
				values[0] = round(ColorArea*1000)/1000;
				values[1] = round(ColorArea*1000/area)/1000;
				if (values[1] == 0)
					values[1] = ColorArea/area;
				roiNumber[0] = roiManager("count");
				//print("Objects in green : "+nResults);
			}
			//If red channel
			else if(endsWith(ShortFileName,"c2"))
			{
				test = 2;
				print("Treating "+ShortFileNameWithoutChannelInfo+" red channel");
				run("Analyze Particles...", "size="+MinSizeObject+"-Infinity pixel show=Overlay display add in_situ");
				ColorArea = 0;
				//Loop through the results
				//print("Objects in green : "+roiNumber[0]+ "nResults : "+nResults);
				for(j=roiNumber[0];j<nResults;j++)
					ColorArea = ColorArea + getResult("Area",j);
				//Values for each channel
				values[2] = round(ColorArea*1000)/1000;
				values[3] = round(ColorArea*1000/area)/1000;
				if (values[3] == 0)
					values[3] = ColorArea/area;
				roiNumber[1] = roiManager("count");

				//Write in the output file
				File.append(ShortFileNameWithoutChannelInfo+"\t"+values[0]+"\t"+values[1]+"\t"+values[2]+"\t"+values[3]+"\t"+area+"\r",Output_Folder+File.separator+TextName);
			}

			close(ImgName);
			//Check if both files exist to make a merge
			if(File.exists(Folder+File.separator+ShortFileNameWithoutChannelInfo+"_c1.tif") && File.exists(Folder+File.separator+ShortFileNameWithoutChannelInfo+"_c2.tif") && test==2)
			{
				print("Treating Overlay");
				//Open the image and convert it
				open(Folder+File.separator+ShortFileNameWithoutChannelInfo+"_c1.tif");
				run("32-bit");
				//Open the image and convert it
				open(Folder+File.separator+ShortFileNameWithoutChannelInfo+"_c2.tif");
				run("32-bit");
				
				//Merge channels
				run("Merge Channels...", "c1=["+ShortFileNameWithoutChannelInfo+"_c2.tif]"+" c2=["+ShortFileNameWithoutChannelInfo+"_c1.tif]");
				selectWindow("RGB");
				//Loop through the green objects to add the overlay
				for(j=0;j<roiNumber[0];j++)
				{
					
					roiManager("Select",j);	
					roiManager("Set Color", "green");
					roiManager("Set Line Width", 2);
					run("Add Selection...");
				}

				selectWindow("RGB");
				//Loop through the red objects to add the overlay
				for(j=roiNumber[0];j<roiNumber[1];j++)
				{
					
					roiManager("Select",j);	
					roiManager("Set Color", "red");
					roiManager("Set Line Width", 2);
					run("Add Selection...");
				}

				run("Flatten");
				saveAs("tiff",Output_Folder+File.separator+"ResultImages"+File.separator+trueYear+trueMonth+trueDay+"AutoThreshold_Size"+MinSizeObject+ShortFileNameWithoutChannelInfo);
				//Reset and close the different windows
				roiManager("Reset");
				roiNumber[0] = 0;
				roiNumber[1] = 0;
				run("Close All");
				close("Results");
				//run("Close");//
			}
		}	
	}
	//Warn when the macro is finished
	showMessage("LiveDeadAnalysis macro finished !");
}	