# RGBD-object-propsal - Changes on this repository

Added a run.py file that uses RGBD-object-propsal prediction over a dataset named "mestrado", subdivided into four sets.
This file also collect some statistics at run.

Changed file HierClustering.m, removed m_pcd_clustering.out call and added pcsegdist(ptCloud, minDistance) call function that implements same algorithm.

Added "features" folder from source code obtained from https://homes.cs.washington.edu/~xren/. Used to generate point clouds and normals from dataset "mestrado". Reference:
Xiaofeng Ren, Liefeng Bo, Dieter Fox
    RGB-(D) Scene Labeling: Features and Algorithms
    IEEE Conference on Computer Vision and Pattern Recognition (CVPR), June, 2012.

Results obtained with "mestrado" dataset will be public available soon, comparing this approach with others semantic sgmentation algorithms.     

# RGBD-object-propsal - original readme

This project addresses the problem of automatically generating high quality class independent object bounding boxes and segmentations using color and depth images of indoor scenes. 
The software is licensed under the GNU General Public License. 
If you use this project for your research, please cite:

    @article{deng2016unsupervised,
      title={Unsupervised object region proposals for RGB-D indoor scenes},
      author={Deng, Zhuo and Todorovic, Sinisa and Latecki, Longin Jan},
      journal={Computer Vision and Image Understanding},
      year={2016},
      publisher={Elsevier}
    }

1 Get the NYU data:
        
    wget http://www.cis.temple.edu/~latecki/TestData/NYUv2data.zip
2 Get precomputed results (plane segmentations, bounding boxes, object segments): 
    
    wget http://www.cis.temple.edu/~latecki/TestData/NYUv2result.zip
