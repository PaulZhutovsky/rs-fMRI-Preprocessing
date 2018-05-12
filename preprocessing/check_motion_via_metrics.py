from glob import glob
import pandas as pd
import os.path as osp
import os
import numpy as np

DATA_FOLDER = '/data/shared/ptsd_police/derivatives/AROMApipeline'
FOLDERS = 'sub-*'
MC_FOLDER = 'func/*.feat/mc'
TR = 2.0  #sec
RESULT_FOLDER = osp.join(DATA_FOLDER, 'analysis', 'groupMaps_metaICA')


def satterthwaite_criterion(fd_values, threshold=0.25):
    contaminated = (fd_values > threshold).sum()
    time_without_volumes = (fd_values.size - contaminated) * TR / 60.
    remove_subject = time_without_volumes < 4.
    crit_dict = {'FD_contaminated_volumes': contaminated,
                 'FD_time_without_volumes_min': time_without_volumes,
                 'FD_remove_subject': remove_subject,
                 'FD_mean': fd_values.mean()}
    return crit_dict


def power_criterion(fd_values, dvars_values, fd_thresh=0.2, dvars_thresh=30):
    contaminated = ((fd_values > fd_thresh) | (dvars_values > dvars_thresh)).sum()
    time_without_volumes = (fd_values.size - contaminated) * TR / 60.
    remove_subject = time_without_volumes < 4.
    crit_dict = {'Power_contaminated_volumes': contaminated,
                 'Power_time_without_volumes_min': time_without_volumes,
                 'Power_remove_subject': remove_subject,
                 'Power_mean_FD': fd_values.mean(),
                 'Power_mean_DVARS': dvars_values.mean()}
    return crit_dict


def motion_param_criterion(mc_par):
    mc_par = np.abs(mc_par)
    mc_par[:, :3] = np.rad2deg(mc_par[:, :3])
    contaminated_2mm = np.any(mc_par > 2, axis=1).sum()
    contaminated_4mm = np.any(mc_par > 4, axis=1).sum()

    time_without_volumes_2mm = (mc_par.shape[0] - contaminated_2mm) * TR / 60.
    time_without_volumes_4mm = (mc_par.shape[0] - contaminated_4mm) * TR / 60.

    remove_subject_2mm = time_without_volumes_2mm < 4.
    remove_subject_4mm = time_without_volumes_4mm < 4.

    crit_dict = {'MCP_contaminated_volumes_2mm': contaminated_2mm,
                 'MCP_time_without_volumes_2mm_min': time_without_volumes_2mm,
                 'MCP_remove_subject_2mm': remove_subject_2mm,
                 'MCP_contaminated_volumes_4mm': contaminated_4mm,
                 'MCP_time_without_volumes_4mm_min': time_without_volumes_4mm,
                 'MCP_remove_subject_4mm': remove_subject_4mm}
    return crit_dict


def run():
    if not osp.exists(RESULT_FOLDER):
        os.makedirs(RESULT_FOLDER)

    subj_ids = [osp.basename(folder) for folder in sorted(glob(osp.join(DATA_FOLDER, FOLDERS)))]

    df_metrics = pd.DataFrame(columns=['subj_id', 'FD_contaminated_volumes', 'FD_time_without_volumes_min',
                                       'FD_remove_subject', 'FD_mean', 'Power_contaminated_volumes',
                                       'Power_time_without_volumes_min', 'Power_remove_subject', 'Power_mean_FD',
                                       'Power_mean_DVARS', 'MCP_contaminated_volumes_2mm',
                                       'MCP_time_without_volumes_2mm_min', 'MCP_remove_subject_2mm',
                                       'MCP_contaminated_volumes_4mm', 'MCP_time_without_volumes_4mm_min',
                                       'MCP_remove_subject_4mm'])

    for i, subj_id in enumerate(subj_ids):
        print '{}/{}'.format(i + 1, len(subj_ids))

        result_subj = {'subj_id': subj_id}

        fd_jenkings = np.loadtxt(glob(osp.join(DATA_FOLDER, subj_id, MC_FOLDER, 'fd_jenkins.txt'))[0])
        fd_power = np.loadtxt(glob(osp.join(DATA_FOLDER, subj_id, MC_FOLDER, 'fd_power.txt'))[0])
        dvars_file = np.loadtxt(glob(osp.join(DATA_FOLDER, subj_id, MC_FOLDER, 'dvars.txt'))[0])
        mc_file = np.loadtxt(glob(osp.join(DATA_FOLDER, subj_id, MC_FOLDER, 'prefiltered_func_data_mcf.par'))[0])

        fd_dict = satterthwaite_criterion(fd_jenkings)
        dvars_dict = power_criterion(fd_power, dvars_file)
        mc_dict = motion_param_criterion(mc_file)

        # combine dictionaries
        result_subj = dict(dict(dict(result_subj, **fd_dict), **dvars_dict), **mc_dict)
        df_metrics = df_metrics.append(result_subj, ignore_index=True)
    df_metrics.to_csv(osp.join(RESULT_FOLDER, 'motion_metrics.csv'), index=False)


if __name__ == '__main__':
    run()
