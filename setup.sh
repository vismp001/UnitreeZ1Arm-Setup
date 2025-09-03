#!/usr/bin/env bash

SYSTEM_USER="INSTALLER"
SETUP_FOLDER=./setup
PACKAGES_FOLDER=$SETUP_FOLDER/packages

log() {
	echo -e "\033[1;32m[$SYSTEM_USER]\033[0m $1"
}

install_from() {
	SRC=$1
	log "Installing packages from $SRC"
	sudo dpkg -i $SRC/*.deb
	sudo apt -f install -y
}

log "Setting up ROS Noetic..."
install_from $PACKAGES_FOLDER/python-minimal
install_from $PACKAGES_FOLDER/python3
install_from $PACKAGES_FOLDER/curl

sleep 30

install_from $PACKAGES_FOLDER/ros-noetic-desktop-full

log "Adding ROS Noetic to source..."
source /opt/ros/noetic/setup.bash
echo "source /opt/ros/noetic/setup.bash" >> ~/.bashrc

log "Installing ROS Noetic dependencies for building packages..."
install_from $PACKAGES_FOLDER/python3-rosdep
install_from $PACKAGES_FOLDER/python3-rosinstall
install_from $SETUP_FOLDER/python3-rosinstall-generator
install_from $PACKAGES_FOLDER/python3-wstool
install_from $PACKAGES_FOLDER/build-essential

#Needs adapting below
sudo rosdep init
rosdep update

# These dependencies are already installed as part of ros-noetic-desktop-full
#install_from $SETUP_FOLDER/libboost-all-dev
#install_from $SETUP_FOLDER/libeigen3-dev
#install_from $SETUP_FOLDER/liburdfdom-dev

log "Setting up Moveit Noetic..."
install_from $PACKAGES_FOLDER/ros-noetic-moveit-*
install_from $PACKAGES_FOLDER/ros-noetic-joint-trajectory-controller 
install_from $PACKAGES_FOLDER/ros-noetic-trac-ik-kinematics-plugin

log "Setting up Python interface..."
install_from $PACKAGES_FOLDER/pinocchio
#Needs adapting below
echo "export LD_LIBRARY_PATH=/usr/local/lib:\$LD_LIBRARY_PATH" >> ~/.bashrc
echo "export CMAKE_PREFIX_PATH=/usr/local:\$CMAKE_PREFIX_PATH" >> ~/.bashrc
echo "export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig:\$PKG_CONFIG_PATH" >> ~/.bashrc

log "Setting up Pybind11..."
install_from $PACKAGES_FOLDER/pybind11

log "Setting up Z1 base dependencies..."
sudo ln -s /usr/include/eigen3/Eigen /usr/local/include/Eigen
sudo ln -s /usr/include/eigen3/unsupported /usr/local/include/unsupported

log "Cloning z1_ros folder..."
if ! [ -d ~/z1_ws/src/z1_ros ]; then
	mkdir -p ~/z1_ws/src
	cp -r $SETUP_FOLDER/z1_ros ~/z1_ws/src
	log "Finished cloning z1_ros to ~/z1_ws/src"
else
	log "z1_ros has already been cloned"
fi

log "Installing Z1 Unitree dependencies..."
cd ~/z1_ws/
rosdep install --from-paths src --ignore-src -yr --rosdistro noetic
# compile unitree_legged_msgs first
catkin_make --pkg unitree_legged_msgs
catkin_make

log "Making commands runnable..."
source /opt/ros/noetic/setup.bash
source ~/z1_ws/devel/setup.bash
echo "source ~/z1_ws/devel/setup.bash" >> ~/.bashrc

log "Please restart the terminal for changes to take effect"
log "You may have to source in the new terminal..."
log "  source /opt/ros/noetic/setup.bash"
log "  source ~/z1_ws/devel/setup.bash""
