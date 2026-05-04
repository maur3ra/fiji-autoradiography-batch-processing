sourcePath = getDirectory("Select folder containing image sequence");
File.makeDirectory("" + sourcePath + "/Documentation");
File.makeDirectory("" + sourcePath + "/Result");

fileList = getFileList(sourcePath);
fileListSeg = getFilesByExtension(fileList, ".tif");


for (i = 0; i < fileListSeg.length; i++) {
	
	if (roiManager("count") > 0) {
		roiManager("Deselect");
		roiManager("Delete");
	}
	
	open("" + sourcePath + "\\" + fileListSeg[i] + "");
	Name = File.nameWithoutExtension();
	rename("slice");
	run("Select None");
	selectWindow("slice");

	//Correction Factor
	run("32-bit");
	run("Square");
	run("Multiply...", "value=4.7562E-5");
	
	//Segment Tracer Area
	run("Set Measurements...", "area mean redirect=None decimal=3");
	run("Enhance Contrast", "saturated=0.35");
	run("Duplicate...", " ");
	selectWindow("slice-1");
	run("8-bit");
	run("Invert LUT");
	
	run("Threshold...");
	waitForUser("Click OK when you are done");
		
	Dialog.create("Input thresholds");
			Dialog.addMessage("Insert here the parameters that you have just annotated");
			Dialog.addMessage("");
			Dialog.addSlider("Min", 0, 255, 111);
			Dialog.addSlider("Max", 0, 255, 255);
			Dialog.show();
			MinThresh=Dialog.getNumber();
			MaxThresh=Dialog.getNumber();
	setThreshold(MinThresh, MaxThresh);
	run("Convert to Mask");
	run("Fill Holes");
	run("Analyze Particles...", "size=300-Infinity pixel clear add");
	run("Select All");

	if (roiManager("count") > 1)  {
		ROI_total = roiManager("count");
		ROI_select = newArray();
		for (k = 0; k < ROI_total; k++) {
			ROI_select = appendToArray(k, ROI_select);
		}
		roiManager("select", ROI_select);
		roiManager("Combine");
		roiManager("Add");
		roiManager("select", ROI_select);
		roiManager("delete");
	}
	
	if (roiManager("count") == 1) {
		selectWindow("slice");
		roiManager("Measure");
		selectWindow("slice");
		run("Select None");
		run("Flip Horizontally");
		run("Select All");
		roiManager("Measure");
		Tracer_Mean = Table.get("Mean", 0);
		Tracer_Area = Table.get("Area", 0);
		CTRL_Mean = Table.get("Mean", 1);
		CTRL_Area = Table.get("Area", 1);

		print("File;" + Name + ";Tracer Mean;" + Tracer_Mean + ";Tracer Area;" + Tracer_Area + ";Control Mean;" + CTRL_Mean + ";Control Area;" + CTRL_Area);
		
		selectWindow("Results");
		run("Close");
	}
	
	if (roiManager("count") == 0) {
		run("Select None");
		selectWindow("slice");
		run("Flip Horizontally");
		print("File;" + Name + ";No ROI");
	}
	
	if (roiManager("count") > 1)  {
		roiManager("Deselect");
		roiManager("Delete");
		run("Select None");
		selectWindow("slice");
		run("Flip Horizontally");
		print("File;" + Name + ";No ROI");
	}
	
	
	//Documentation
	run("Select None");
	selectWindow("slice");
	run("Flip Horizontally");
	roiManager("Show All");
	roiManager("Show All without labels");
	roiManager("Set Color", "magenta");
	roiManager("Set Line Width", 3);
	run("Flatten");
	rename("docu_ROI");
	selectWindow("docu_ROI");
	saveAs("PNG", "" + sourcePath + "/Documentation/" + Name + "_docu.PNG");
	
	run("Close All");
}

selectWindow("Log");
saveAs("Text", "" + sourcePath +  "/Result/Result.csv" );
