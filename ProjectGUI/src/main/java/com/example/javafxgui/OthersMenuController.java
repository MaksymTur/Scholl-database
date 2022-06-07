
package com.example.javafxgui;

import javafx.event.ActionEvent;
import javafx.fxml.FXML;
import javafx.fxml.FXMLLoader;
import javafx.scene.Node;
import javafx.scene.Parent;
import javafx.scene.control.Spinner;
import javafx.scene.control.SpinnerValueFactory;
import javafx.stage.Stage;

import java.io.IOException;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Time;
import java.time.LocalTime;

import static com.example.javafxgui.HelloApplication.conn;

public class OthersMenuController {

    @FXML Spinner<Integer> lessonPicker;

    @FXML Spinner<Integer> beginHourPicker;
    @FXML Spinner<Integer> beginMinutePicker;
    @FXML Spinner<Integer> endHourPicker;
    @FXML Spinner<Integer> endMinutePicker;



    void initInfo() {
    }

    {
        initInfo();
    }

    @FXML
    void goToMenu(ActionEvent event) {
        Stage stage = (Stage) ((Node) event.getSource()).getScene().getWindow();
        try {
            Parent root = new FXMLLoader(MainMenuController.class.getResource("main-menu-view.fxml")).load();
            stage.getScene().setRoot(root);
        } catch (IOException e) {
            throw new RuntimeException(e);
        }
    }

    @FXML
    void onRemoveBell(){
        try(PreparedStatement st = conn.prepareStatement("INSERT INTO bell_schedule_history(bell_order, begin_time, end_time) VALUES (?, NULL, NULL)")){
            st.setInt(1, lessonPicker.getValue());
            st.executeUpdate();
            conn.commit();
        } catch (SQLException e) {
            try{
                conn.rollback();
            } catch (SQLException ex) {
                throw new RuntimeException(ex);
            }
            throw new RuntimeException(e);
        }
    }

    @FXML
    void onSetBell(){
        try(PreparedStatement st = conn.prepareStatement("SELECT add_bell(?, ?, ?)")){
            LocalTime begin = LocalTime.of(beginHourPicker.getValue(), beginMinutePicker.getValue());
            LocalTime end = LocalTime.of(endHourPicker.getValue(), endMinutePicker.getValue());
            st.setInt(1, lessonPicker.getValue());
            st.setTime(2, Time.valueOf(begin));
            st.setTime(3, Time.valueOf(end));
            st.executeQuery();
            conn.commit();
        } catch (SQLException e) {
            try{
                conn.rollback();
            } catch (SQLException ex) {
                throw new RuntimeException(ex);
            }
            throw new RuntimeException(e);
        }
    }

    void showCurrentBellBounds(){
        try(PreparedStatement st = conn.prepareStatement("SELECT bell_begin_time(?), bell_end_time(?)")){
            st.setInt(1, lessonPicker.getValue());
            st.setInt(2, lessonPicker.getValue());
            ResultSet res = st.executeQuery();
            if(res.next() && res.getTime(1) != null) {
                LocalTime begin = res.getTime(1).toLocalTime();
                LocalTime end = res.getTime(2).toLocalTime();
                beginHourPicker.getValueFactory().setValue(begin.getHour());
                beginMinutePicker.getValueFactory().setValue(begin.getMinute());
                endHourPicker.getValueFactory().setValue(end.getHour());
                endMinutePicker.getValueFactory().setValue(end.getMinute());
            }
        } catch (SQLException e) {
            throw new RuntimeException(e);
        }
    }

    @FXML
    void initialize() {
        lessonPicker.setValueFactory(new SpinnerValueFactory.IntegerSpinnerValueFactory(0, 20));
        lessonPicker.valueProperty().addListener((observable, oldValue, newValue) -> showCurrentBellBounds());

        beginHourPicker.setValueFactory(new SpinnerValueFactory.IntegerSpinnerValueFactory(0, 23));
        beginMinutePicker.setValueFactory(new SpinnerValueFactory.IntegerSpinnerValueFactory(0, 59));
        endHourPicker.setValueFactory(new SpinnerValueFactory.IntegerSpinnerValueFactory(0, 23));
        endMinutePicker.setValueFactory(new SpinnerValueFactory.IntegerSpinnerValueFactory(0, 59));
    }
}
